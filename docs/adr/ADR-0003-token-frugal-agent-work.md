# ADR-0003: Spend tokens like they are a budget, because they are

**Status:** Accepted
**Date:** 2026-08-22
**Scope:** All KavanaraOrg repositories
**Applies to:** agents, and the tooling built for them

## Context

Tokens are the scarce resource in agent work, and they are spent in ways that
feel free at the moment of spending. Reading a 45,000-line `README.md` to
answer a question about one flag costs the same as reading it to rewrite the
whole thing. Re-deriving a fact that a deterministic script could compute costs
orders of magnitude more than running the script — and is less reliable, because
arithmetic and enumeration are exactly what a language model is worst at.

The failure is rarely one extravagant call. It is a thousand small ones: whole
files read when a `grep` would do, results restated back to the user in full,
a directory listed three times in one turn, an answer re-derived because the
previous answer was not written down anywhere durable.

The house tooling already reflects this where someone thought about it. The
`tg-konformitaet` skill states plainly that its job is *to run the bundled
scripts and report — not to re-derive product data by hand*. `tg-maintain` says
the same. `limen backlog` exists so an agent can ask "where is something open?"
with one process start instead of reading every `notes.md` on the machine.
What is missing is the general rule those instances are examples of.

## Decision

**Prefer the cheapest tool that can answer the question, in this order:**

1. A deterministic script or CLI that computes the answer exactly
   (`limen list --json`, a validator, a query). Reasoning is not applied to
   arithmetic, enumeration or lookup when a program can do it.
2. A targeted search — `grep`, a symbol lookup, a line range.
3. Reading a whole file, when the whole file is genuinely the subject.
4. Reasoning from what is already in context.

**Read narrowly.** Request the lines needed, not the file that contains them.
Do not re-read a file just written; do not re-run a command whose output is
already in context.

**Batch independent work.** Calls with no dependency between them go out
together, not in sequence.

**Delegate what produces bulk.** A broad search across many files goes to a
subagent that returns the conclusion, so the file dumps never enter the main
context.

**Structure output for machines where a machine is the reader.** `--json`
exists so an agent does not parse prose. Tools built here provide it.

**Say it once.** Do not restate a tool result the user can see, do not
summarise a summary, and do not preface an answer with what the answer is about
to be.

**Write facts down instead of re-deriving them.** A durable answer belongs in
`.limen/notes.md`, an ADR, or a memory — somewhere the next session reads
cheaply — not in a chat message that scrolls away.

**Frugality is never an excuse for incomplete work.** Skipping a required check,
truncating a list without saying so, or answering from memory rather than
verifying is not thrift; it is a wrong answer, delivered cheaply. When coverage
must be bounded, say what was left out.

## Consequences

- Tooling in these repositories is expected to offer a machine-readable mode
  and to be runnable without a language model in the loop. That is a design
  constraint on what gets built, not only on how it is used.
- Answers get shorter. Some of what disappears is padding that read as
  diligence; that is the intended trade.
- The rule is enforced by a skill (`kavanara-token-frugal`), because a principle
  nobody reads at the moment of acting changes nothing.

## Alternatives considered

**A hard token cap per task.** Rejected: it fails the last clause above. A cap
does not make work cheaper, it makes it stop halfway, and a truncated audit is
more expensive than a complete one because it has to be redone.

**No rule; rely on the model's defaults.** Rejected on evidence — the defaults
are tuned for a general case, and this case has house tooling built precisely
so that reasoning does not have to be spent on things a script can compute.
