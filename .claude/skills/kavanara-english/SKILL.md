---
name: kavanara-english
description: Enforces English as the working language for everything committed to a KavanaraOrg repository — code, comments, identifiers, documentation, ADRs, commit messages, test names, error strings and API descriptions — while conversation with the user stays in whatever language they write. ALWAYS consult before creating or editing any file in the repository, and before writing a commit message. Use it also when the user asks in German for a document, a README, an ADR or a code comment: the reply is German, the file is English. Keywords: language, Sprache, English, Englisch, Deutsch, documentation, Doku, README, ADR, commit message, comment, Kommentar, translate, übersetzen, rename, i18n.
---

# English is the working language

Full reasoning: `ADR-0001-english-is-the-working-language`.

## The rule

Everything that lands in the repository is English. Everything said to the user
is in the user's language.

These two are independent. A German prompt does not produce a German file, and
writing an English file does not oblige you to answer in English.

## Covered

- Source code: identifiers, comments, log messages, error strings, constants
- Documentation: README, ADRs, architecture notes, runbooks, whitepapers
- Commit messages, branch names, PR titles and bodies
- Test names and test failure messages
- Schema and API descriptions: OpenAPI summaries, JSON-Schema `description`

## Not covered

- Chat with the user. Answer in the language they used.
- Voice notes, meeting transcripts, issue discussion — not repository artefacts.
- `.limen/notes.md`. Rolling notes are captured thinking, not documentation;
  they keep the language they were dictated in.

## The two exceptions

**Verbatim source material.** Quoted requirements, customer wording and meeting
transcripts keep their original language — translating a quote destroys its
value as evidence. Mark it: a `-de` filename suffix, or a directory that names
the language.

**Untranslatable domain terms.** *Kreis*, *Rolle*, *Normenhierarchie* and
similar terms from the organisational model may stay German where an English
word would assert a false equivalence. Introduce each once with a gloss, then
use it consistently. This licenses individual terms, never whole sentences.

## Working with what is already there

Do not launch a translation sweep. A German file that nobody is editing is not
a problem worth spending on.

- **Editing a German file substantially?** Translate it as part of the change.
- **Making a one-line fix in a German file?** Leave the language alone. A file
  half-translated is worse than one consistently German.
- **Creating a file?** English, always, whatever language the request was in.

## Checks before you finish

1. Every file you created or substantially rewrote is English throughout —
   including comments, log lines and error strings, which are the ones that
   slip through.
2. The commit message is English.
3. Any German you deliberately kept falls under one of the two exceptions and
   is recognisable as deliberate.
