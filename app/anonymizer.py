from __future__ import annotations

import logging
import os
import threading
import time
from collections import defaultdict

from app.exclusions import find_exclusion_ranges, merge_exclusions, overlaps_exclusion
from app.models import AnonymizeRequest, AnonymizeResponse, DetectedEntity
from app.protected_terms import find_protected_term_spans, merge_protected_terms

logger = logging.getLogger(__name__)

_opf_instance = None
_opf_init = threading.Lock()

# How many texts the model works on at once. Inference on the CPU already uses every core for one text; several at
# once only share them, so each takes as long as all of them together and every caller runs into its timeout.
_CONCURRENCY = max(1, int(os.getenv("ANONYMIZER_CONCURRENCY", "1")))
_slots = threading.BoundedSemaphore(_CONCURRENCY)

# A long text goes to the model in pieces of about this many characters, split at paragraph (else line, sentence,
# word) boundaries. Between two pieces the slot is given up, so a short text never waits for a whole long one, and a
# request whose caller left stops at the next piece instead of running to its end.
_SEGMENT_CHARS = max(500, int(os.getenv("ANONYMIZER_SEGMENT_CHARS", "8000")))


class AnonymizationCancelled(Exception):
    """The caller is gone (or gave up); the rest of the text is not worked on."""

CATEGORY_MAP = {
    "account_number": "ACCOUNT",
    "private_address": "ADDRESS",
    "email_address": "EMAIL",
    "person": "PERSON",
    "phone_number": "PHONE",
    "url": "URL",
    "date": "DATE",
    "secret": "SECRET",
}


def get_opf():
    from opf import OPF

    global _opf_instance
    with _opf_init:
        if _opf_instance is None:
            logger.info("Initializing OPF model (first request, this may take a moment)...")
            _opf_instance = OPF(device="cpu", output_mode="typed")
    return _opf_instance


def segments(text: str, limit: int | None = None) -> list[tuple[int, str]]:
    """The text in pieces of at most `limit` characters, each with its offset; together they are the text."""
    limit = limit or _SEGMENT_CHARS
    pieces: list[tuple[int, str]] = []
    start = 0
    while len(text) - start > limit:
        window = text[start : start + limit]
        cut = 0
        for sep in ("\n\n", "\n", ". ", " "):
            i = window.rfind(sep, limit // 2)
            if i >= 0:
                cut = i + len(sep)
                break
        if cut <= 0:
            cut = limit
        pieces.append((start, text[start : start + cut]))
        start += cut
    pieces.append((start, text[start:]))
    return pieces


def _take_slot(cancel: threading.Event | None) -> None:
    while not _slots.acquire(timeout=0.5):
        if cancel is not None and cancel.is_set():
            raise AnonymizationCancelled()


def _detect(text: str, cancel: threading.Event | None) -> list[tuple[str, int, int]]:
    """The model's spans over the whole text as (label, start, end), worked piece by piece, one text at a time."""
    found: list[tuple[str, int, int]] = []
    pieces = segments(text)
    began = time.monotonic()
    for offset, piece in pieces:
        if cancel is not None and cancel.is_set():
            raise AnonymizationCancelled()
        if not piece.strip():
            continue
        _take_slot(cancel)
        try:
            result = get_opf().redact(piece)
        finally:
            _slots.release()
        for span in result.detected_spans:
            label = span.label.lower() if hasattr(span, "label") else "unknown"
            found.append((label, offset + span.start, offset + span.end))
    if len(pieces) > 1:
        logger.info("anonymize: %d characters in %d pieces, %.1f s", len(text), len(pieces), time.monotonic() - began)
    return found


def anonymize(request: AnonymizeRequest, cancel: threading.Event | None = None) -> AnonymizeResponse:
    """Anonymize the request's text. With `cancel` set (the caller left), stops at the next piece of the text."""
    detected = _detect(request.text, cancel)

    exclusions = merge_exclusions(request.exclusions)
    exclusion_ranges = find_exclusion_ranges(request.text, exclusions) if exclusions else []

    protected = merge_protected_terms(request.protected_terms)
    custom_spans = find_protected_term_spans(request.text, protected) if protected else []

    counters: dict[str, int] = defaultdict(int)
    entities: list[DetectedEntity] = []
    mapping: dict[str, str] = {}

    raw_spans: list[tuple[str, str, int, int]] = []

    for label, start, end in detected:
        if request.categories and label not in request.categories:
            continue

        if overlaps_exclusion(start, end, exclusion_ranges):
            continue

        tag = CATEGORY_MAP.get(label, label.upper())
        original_text = request.text[start:end]
        raw_spans.append((tag, original_text, start, end))

    for category, original_text, start, end in custom_spans:
        raw_spans.append((category, original_text, start, end))

    merged = _merge_spans(raw_spans)

    for tag, original_text, start, end in merged:
        counters[tag] += 1
        placeholder = f"[{tag}_{counters[tag]}]"
        mapping[placeholder] = original_text
        entities.append(
            DetectedEntity(
                placeholder=placeholder,
                original=original_text,
                category=tag.lower(),
                start=start,
                end=end,
            )
        )

    anonymized = _replace_spans(request.text, entities)

    return AnonymizeResponse(
        anonymized_text=anonymized,
        mapping=mapping,
        entities=entities,
        exclusions_applied=exclusions,
        protected_terms_applied=protected,
    )


def _merge_spans(spans: list[tuple[str, str, int, int]]) -> list[tuple[str, str, int, int]]:
    """Merge PII and custom spans, removing overlaps. Earlier/longer spans win."""
    sorted_spans = sorted(spans, key=lambda s: (s[2], -(s[3] - s[2])))
    result: list[tuple[str, str, int, int]] = []
    last_end = -1
    for span in sorted_spans:
        if span[2] >= last_end:
            result.append(span)
            last_end = span[3]
    return result


def _replace_spans(text: str, entities: list[DetectedEntity]) -> str:
    result = text
    for entity in sorted(entities, key=lambda e: e.start, reverse=True):
        result = result[: entity.start] + entity.placeholder + result[entity.end :]
    return result
