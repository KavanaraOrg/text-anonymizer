# ADR-0002: Test-driven development is the default way to build

**Status:** Accepted, amended in part by ADR-0004
**Date:** 2026-08-22
**Scope:** All KavanaraOrg repositories
**Applies to:** humans and agents alike

> **Amended by ADR-0004 (2026-08-23).** Two statements below no longer hold as
> written: the consequence "No coverage percentage is mandated", and the
> rejection of a coverage gate under *Alternatives considered*. ADR-0004 adds a
> per-module coverage **floor** of 75% and a required bug-pattern analyzer. The
> reasoning here is not withdrawn — coverage is still not a target and this
> document still governs *why* a test gets written. ADR-0004 answers a different
> question: how an area the loop never reached gets noticed.

## Context

An agent that writes code and then writes tests for it produces tests that
agree with the code. They agree because they were derived from it — including
where the code is wrong. Such a suite is green, large, and proves close to
nothing. It is also expensive: it must be read and maintained forever while
answering a question nobody asked.

Writing the test first inverts the derivation. The test is derived from the
requirement, and the code is then obliged to satisfy something stated
independently of it. The suite becomes a record of intent rather than a
restatement of implementation.

There is a second reason, specific to agents. A failing test is an unambiguous
goal with an unambiguous termination condition. It removes the most common
failure mode of an autonomous change — declaring success on work that was never
verified — and it removes the second most common one, drifting scope, because
the test bounds what "done" means.

`limen` itself is the evidence that this is affordable at this scale: 111 test
cases against roughly 1,500 lines of Go, and the tests pin behaviour that is
genuinely load-bearing (`limen shell` stays silent and exits 0 without a
context, because otherwise it could not be called unconditionally from a
`.zshrc`).

## Decision

**Red, green, refactor — in that order, for every behavioural change.**

1. Write a test that fails for the right reason. Run it and read the failure;
   a test that passes on first run has not been shown to test anything.
2. Write the least code that makes it pass.
3. Refactor with the test as the safety net.

**A test names the behaviour, not the function.** `TestShellIsSilentWithoutAContext`
is a specification; `TestRenderShell` is a coordinate. Test names are read most
often as failure output, where the useful information is which promise broke.

**Comment the why in the test.** Where a test pins a non-obvious decision, the
test says what would go wrong otherwise. This is where reasoning survives; a
future reader deleting a test they do not understand is how regressions return.

**Negative controls where a suite could pass vacuously.** If a check could
succeed by never executing, add a case that proves it fails when it should.

**Exempt** from test-first, because the cost exceeds the benefit:

- pure formatting, renames, and comment changes
- generated code, and the generator's output as opposed to the generator
- exploratory spikes explicitly marked as throwaway and never merged
- one-off scripts under `scripts/` that are run by hand and read before each run

**Not exempt:** bug fixes. A bug is a missing test by definition. The
reproduction comes first and fails; the fix turns it green.

## Consequences

- Changes take longer to start and less time to finish. The wall-clock cost
  lands mostly on the first change to an untested area.
- Coverage stops being a target and becomes a by-product. No coverage
  percentage is mandated; a suite written this way covers what matters and
  ignores what does not.
- Agents get a verifiable definition of done, which is the point. "The test
  passes" is checkable; "I implemented it" is not.
- Legacy code without tests is not retrofitted on principle. The first change
  to a file brings the test that change requires.

## Alternatives considered

**Tests after, with a coverage gate.** The common compromise, and rejected for
the reason above: the tests agree with the code by construction, and a coverage
gate rewards the tests that prove least because they are the cheapest to write.

**Tests only at integration level.** Fast to write, slow to run, and vague
about where a failure lives. Kept as a complement — `limen` runs its built
binary in real directories — but not as a substitute.
