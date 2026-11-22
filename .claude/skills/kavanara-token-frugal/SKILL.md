---
name: kavanara-token-frugal
description: Enforces token-frugal work in KavanaraOrg repositories — prefer a deterministic script or CLI over re-deriving an answer by reasoning, read narrowly instead of whole files, batch independent calls, delegate bulk searches to a subagent, and say things once. ALWAYS consult before starting an investigation, a repository-wide search, an audit, or any task that will read many files. Also covers what frugality never licenses: skipping a required check or truncating a result without saying so. Keywords: token, tokens, budget, cost, expensive, context, sparsam, effizient, search, grep, read files, audit, investigate, scan, repository-wide, summarize, report, script instead of reasoning.
---

# Spend tokens like a budget

Full reasoning: `ADR-0003-token-frugal-agent-work`.

## Cheapest tool that answers the question

In order. Stop at the first that works.

1. **A deterministic program.** `limen list --json`, `limen backlog --json`, a
   validator, a SQL query, a bundled script. Never apply reasoning to
   arithmetic, enumeration or lookup that a program can do exactly — it costs
   more and it is less reliable.
2. **A targeted search.** `grep`, a symbol lookup, a line range.
3. **A whole file**, when the whole file is genuinely the subject.
4. **Reasoning** from what is already in context.

Before reading a large file, ask what specific thing you need from it. That
answer is usually a `grep` pattern.

## Habits

- **Read narrowly.** The lines you need, not the file containing them.
- **Never re-read what you just wrote.** The edit would have errored if it failed.
- **Never re-run a command whose output is already in context.**
- **Batch.** Independent calls go out in one turn, not one after another.
- **Delegate bulk.** A sweep across many files goes to a subagent that returns
  the conclusion — the file dumps stay out of the main context.
- **Say it once.** Do not restate a tool result the user can see. Do not
  summarise your own summary. Do not announce what you are about to say.
- **Write facts down.** Something worth knowing next session goes to
  `.limen/notes.md`, an ADR, or a memory — not into a chat message that scrolls
  away and has to be re-derived.

## When building tooling

Anything built in these repositories offers a machine-readable mode
(`--json`) and runs without a language model in the loop. An agent should be
able to get a fact by running one process, not by reading and reasoning. This
is a design constraint on what gets built, not only on how it is used.

## What this never licenses

Frugality is about *how* the work is done, never about doing less of it.

- Do not skip a check the task requires.
- Do not truncate a list, a search or an audit silently. If coverage is
  bounded, say what was left out and why.
- Do not answer from memory when the answer is verifiable. A wrong answer
  delivered cheaply is the most expensive outcome available.
- Do not shorten a deliverable the user asked for. Padding is what gets cut,
  not scope.
