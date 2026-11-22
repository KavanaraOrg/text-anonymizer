---
name: kavanara-test-first
description: Enforces test-driven development in KavanaraOrg repositories — write a failing test first, watch it fail for the right reason, then write the least code that makes it pass. ALWAYS consult before implementing a feature, changing behaviour, or fixing a bug, and before reporting any implementation as done. Covers what is exempt (formatting, generated code, throwaway spikes), why bug fixes never are, how to name a test after the behaviour it pins, and when a negative control is needed. Keywords: test, tests, testing, TDD, test-driven, unit test, red green refactor, failing test, coverage, bug, fix, regression, reproduce, implement, feature, refactor.
---

# Test first

Full reasoning: `ADR-0002-test-driven-development`.

## The loop

1. **Red.** Write a test for the behaviour you are about to build. Run it.
   Read the failure and confirm it fails for the reason you intended.
   A test that passes on its first run has not been shown to test anything —
   find out why before continuing.
2. **Green.** Write the least code that makes it pass. Not the design you
   expect to need later; the code this test demands.
3. **Refactor.** Improve the shape with the test holding the behaviour still.

Do not batch this. One behaviour, one loop.

## Naming

Name the test after the promise it pins, not the function it calls.

```
TestShellIsSilentWithoutAContext        good — a specification
TestRenderShell                         poor — a coordinate
TestSyncRemovesFilesTheProfileNoLongerCarries    good
TestProfileSync2                        poor
```

Test names are read most often as failure output. The useful information there
is *which promise broke*, not *where the code lives*.

## Comment the why

Where a test pins a non-obvious decision, write what would go wrong without it.
Reasoning that lives only in a commit message is reasoning that is gone.

```go
// A norm that was withdrawn must disappear from the project, or the agent
// keeps obeying a rule nobody holds any more.
func TestSyncRemovesFilesTheProfileNoLongerCarries(t *testing.T) {
```

## Negative controls

If a check could pass by never executing — a test harness, a validator, a
generated suite — add a case that proves it fails when it should. Without one,
the checks above it can be green because nothing ran.

## Exempt

- Formatting, renames, comment-only changes
- Generated code (the generator is not exempt; its output is)
- Exploratory spikes explicitly marked throwaway and never merged
- Hand-run one-off scripts under `scripts/`, read before each run

## Never exempt: bug fixes

A bug is a missing test. The order is fixed:

1. Write a test that reproduces the bug. It fails.
2. Fix the code. It passes.
3. Keep the test.

Fixing first and testing after produces a test derived from the fix, which
proves the fix does what it does rather than what it should.

## Legacy code

Untested code is not retrofitted on principle. The first change to a file
brings the test that change requires — no more.

## Before reporting done

- The new tests failed before the change and pass after it.
- The full suite passes. If any test fails, say so and show the output;
  a partial pass reported as success is the failure mode this exists to prevent.
- No test was weakened or deleted to get to green. If one had to change, say
  which and why.
