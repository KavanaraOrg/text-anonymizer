# ADR-0001: English is the working language for code and documentation

**Status:** Accepted
**Date:** 2026-08-22
**Scope:** All KavanaraOrg repositories
**Applies to:** humans and agents alike

## Context

Work in these repositories happens in two languages. Conversation, voice notes,
meetings and thinking are German; the artefacts are read by a much wider set of
readers than the people who produced them — contributors, open-source users,
tooling, and language models whose training and reasoning are strongest in
English.

Without a written rule, the language of an artefact ends up matching the
language of the prompt that produced it. That is how `Tessera/docs/` came to
hold `TESSERA-WHITEPAPER.md` and `BEISPIELLAUF.md` in German while the other
seventeen documents in the same directory are English. Nobody decided that; the
`Conventions` section of `Tessera/CLAUDE.md` said, verbatim, *"Conventions not
yet established"*, so there was nothing to decide it.

Mixed-language documentation is worse than either language consistently
applied. A reader cannot tell from a filename which language a document is in,
terms drift between their German and English forms across documents that
reference each other, and translation debt compounds: each new German document
raises the cost of ever standardising.

## Decision

**Everything committed to a repository is written in English.** This covers:

- source code — identifiers, comments, log messages, error strings
- documentation — README, ADRs, architecture notes, runbooks, whitepapers
- commit messages, branch names, pull-request titles and descriptions
- test names and test failure messages
- schema and API descriptions, OpenAPI summaries, JSON-Schema `description`

**Conversation stays German.** Chat with an agent, voice notes, meeting
transcripts, and issue discussion are not artefacts of the repository and are
explicitly out of scope. An agent asked a question in German answers in German,
and writes the resulting file in English.

**Two exceptions**, both narrow and both requiring the German to be the point
rather than an accident:

1. **Verbatim source material.** Meeting transcripts, quoted requirements and
   customer wording keep their original language. Translating a quote destroys
   its evidentiary value. Such files carry a `-de` suffix or live under a
   directory that names the language.
2. **Domain terms with no faithful translation.** *Kreis*, *Rolle*,
   *Normenhierarchie* and similar terms from the organisational model may stay
   German where translating would introduce a false equivalence. They are
   introduced once with a gloss, then used consistently.

## Consequences

- Existing German documents are not rewritten wholesale. They are translated
  when they are next substantially edited, so the cost is paid where work is
  already happening. A file nobody touches is a file nobody is confused by.
- `CLAUDE.md` in every repository states the rule, so an agent reads it before
  writing rather than after being corrected.
- The rule is enforced by a skill (`kavanara-english`), not only by this record:
  an ADR explains why, a skill changes what happens.
- German prompts stay natural. This ADR asks nothing of how anyone talks.

## Alternatives considered

**German throughout.** Coherent, and it matches how the work is actually
discussed. Rejected because these repositories are Apache-licensed and public,
and because the agents doing much of the writing produce measurably better
technical English than technical German.

**Per-repository choice.** Rejected: ADRs, schemas and glossaries cross
repository boundaries constantly — `Tessera/docs/CIRCLEAD-MAPPING.md` is about
two repositories at once. A per-repository rule would put the seam inside
documents rather than between them.

**Bilingual documents.** Rejected as unmaintainable. In practice one language
is updated and the other silently rots into a lie.
