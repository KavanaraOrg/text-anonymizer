import threading
import time
from types import SimpleNamespace

import pytest

from app import anonymizer
from app.anonymizer import AnonymizationCancelled, anonymize, segments
from app.models import AnonymizeRequest


class FakeOpf:
    """Finds every "Ben Example" and remembers how many texts it worked on at once."""

    def __init__(self, delay: float = 0.0):
        self.delay = delay
        self.calls: list[str] = []
        self.active = 0
        self.most_at_once = 0
        self.lock = threading.Lock()

    def redact(self, text: str):
        with self.lock:
            self.active += 1
            self.most_at_once = max(self.most_at_once, self.active)
            self.calls.append(text)
        time.sleep(self.delay)
        spans = []
        i = text.find("Ben Example")
        while i >= 0:
            spans.append(SimpleNamespace(label="person", start=i, end=i + len("Ben Example")))
            i = text.find("Ben Example", i + 1)
        with self.lock:
            self.active -= 1
        return SimpleNamespace(detected_spans=spans)


@pytest.fixture
def opf(monkeypatch):
    fake = FakeOpf()
    monkeypatch.setattr(anonymizer, "get_opf", lambda: fake)
    return fake


def test_segments_are_the_text_with_their_offsets():
    text = ("Absatz eins mit Ben Example.\n\n" * 50) + ("ein langer Satz ohne Umbruch " * 40)
    pieces = segments(text, 500)
    assert "".join(p for _, p in pieces) == text
    assert all(len(p) <= 500 for _, p in pieces)
    for offset, piece in pieces:
        assert text[offset : offset + len(piece)] == piece


def test_segments_split_at_paragraphs_first():
    text = "a" * 300 + "\n\n" + "b" * 300 + "\n" + "c" * 300
    first = segments(text, 500)[0][1]
    assert first.endswith("\n\n")


def test_a_short_text_is_one_piece():
    assert segments("kurz", 500) == [(0, "kurz")]


def test_spans_of_later_pieces_point_into_the_whole_text(opf, monkeypatch):
    monkeypatch.setattr(anonymizer, "_SEGMENT_CHARS", 500)
    text = ("Füllsatz ohne Namen.\n\n" * 40) + "Ben Example schreibt."
    result = anonymize(AnonymizeRequest(text=text))
    assert len(opf.calls) > 1
    assert result.mapping == {"[PERSON_1]": "Ben Example"}
    assert result.anonymized_text.endswith("[PERSON_1] schreibt.")


def test_a_cancelled_request_stops_before_its_next_piece(opf, monkeypatch):
    monkeypatch.setattr(anonymizer, "_SEGMENT_CHARS", 500)
    cancel = threading.Event()
    real = opf.redact

    def redact_then_leave(text):
        cancel.set()  # the caller leaves while the first piece is worked on
        return real(text)

    opf.redact = redact_then_leave
    with pytest.raises(AnonymizationCancelled):
        anonymize(AnonymizeRequest(text="Satz ohne Namen.\n\n" * 200), cancel)
    assert len(opf.calls) == 1


def test_texts_are_worked_on_one_at_a_time(monkeypatch):
    fake = FakeOpf(delay=0.05)
    monkeypatch.setattr(anonymizer, "get_opf", lambda: fake)
    threads = [
        threading.Thread(target=anonymize, args=(AnonymizeRequest(text=f"Text {i} von Ben Example"),))
        for i in range(6)
    ]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    assert len(fake.calls) == 6
    assert fake.most_at_once == 1
