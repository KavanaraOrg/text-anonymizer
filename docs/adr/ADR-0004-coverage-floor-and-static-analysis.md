# ADR-0004: A coverage floor and a bug-pattern analyzer, alongside test-first

**Status:** Accepted
**Date:** 2026-08-23
**Scope:** All KavanaraOrg repositories
**Applies to:** humans and agents alike
**Amends:** ADR-0002 (the "no coverage percentage is mandated" consequence, and the
rejection of a coverage gate under Alternatives considered)

## Context

ADR-0002 made test-first the default and drew an explicit conclusion from it:
"Coverage stops being a target and becomes a by-product. No coverage percentage
is mandated." It rejected "tests after, with a coverage gate" because such a
gate "rewards the tests that prove least because they are the cheapest to
write."

That reasoning is sound and is not withdrawn here. It answers the question *what
should drive test writing* — and the answer is still the failing test, not a
percentage. But it leaves a second question unanswered: *how do we notice an
area the loop never reached?*

Test-first governs new behaviour. It says nothing about code that predates the
norm, code merged under time pressure with the loop skipped, or a module whose
tests all sit at one level and leave a layer beneath them unexercised. ADR-0002
even names this gap and accepts it: "Legacy code without tests is not
retrofitted on principle." That is a reasonable stance for a file nobody edits.
It is not a reasonable stance for a module that is 42% covered and holds tenant
isolation.

Tessera made the gap concrete. It measures coverage but gates it at 16% — a
value derived, correctly and honourably, as the lowest measured per-module ratio
minus headroom, with the note "raise this value as coverage improves; never
lower." Actual coverage is 61.7% overall, with a 44-point spread between modules
(fabric-rules 86.4%, agnostic-crdt 42.0%). Nothing in the norms said which of
those numbers was acceptable, so the gate could only ratchet behind reality
instead of pulling it.

There is a parallel gap in static analysis. Tessera runs a formatter, a
dependency enforcer, and 22 architecture rule files, and none of them inspect a
method body. A first run of a bug-pattern analyzer over it surfaced a
non-atomic check-then-act in key provisioning and two null-path findings that no
existing gate could have seen.

## Decision

**A floor, not a target — and an analyzer that reads method bodies.**

1. **Line coverage must not fall below 75% per module.** This is a floor: it
   marks the level below which an area is presumed unexercised, not a number to
   optimise toward. A module at 95% is not better-governed than one at 80%; a
   module at 40% is telling you something.

2. **The floor is a ratchet where it is not yet met.** A repository below 75%
   records its current lowest per-module ratio as the enforced value, raises it
   as coverage improves, and never lowers it. Declaring 75% on day one and
   leaving the build red serves nobody. The obligation is monotonic progress
   with a known destination, not an immediate cliff.

3. **Coverage is still not a target, and this does not licence tests-after.**
   The route to the floor is the ADR-0002 loop applied to the next change in
   that area. A test written only to move a percentage is a test ADR-0002
   already rejected, and this ADR does not readmit it.

4. **Every repository runs a bug-pattern analyzer over its own sources.**
   Formatters, dependency rules and architecture rules do not substitute for
   one: they check shape, not behaviour inside a method. Generated code is
   excluded, and every other exclusion carries its reason in the same file — an
   exclusion without a stated reason is indistinguishable from a hidden defect.

5. **The analyzer starts as a report and becomes a gate.** A first run over an
   existing codebase produces findings nobody has triaged; gating on them
   immediately reddens the build without adding information. Triage first, then
   arm it.

## Consequences

- A module can now fail for being untested, which ADR-0002 deliberately did not
  allow. That is the intended change.
- The ratchet means the floor is enforced unevenly across repositories for a
  while, and each one's current value has to be readable from its build. A
  single named property, as in Tessera's `jacoco.line.coverage.minimum`, is the
  shape to copy.
- ADR-0002's objection survives in a narrower form: a floor still rewards the
  cheapest tests that reach it. The ratchet limits the damage — it moves with
  measured coverage rather than being negotiated per change — but it does not
  eliminate it, and a reviewer seeing coverage-shaped tests should say so.
- Two more gates means two more ways for CI to be red for reasons unrelated to
  the change in front of you. Both are cheap to read and neither is
  flaky-by-nature, which is why they are acceptable where a performance gate
  would not be.

## Alternatives considered

**Leave ADR-0002 as it stands.** The gap is real and was demonstrated, not
hypothesised: a 42%-covered module holding tenant isolation is not a by-product
of a healthy loop, it is an area the loop never entered.

**A repository-wide aggregate instead of per-module.** An aggregate lets a large
well-tested module carry a small untested one, which is precisely the situation
the floor exists to surface.

**A stricter floor (90%).** Buys little over 75% and starts rewarding tests
written for the metric — the failure mode ADR-0002 named. 75% is high enough
that an unexercised layer shows up and low enough that reaching it does not
require testing trivia.

**Branch or mutation coverage instead of line coverage.** Both are better
signals. Neither is cheap to adopt uniformly today, and line coverage already
separates "tested" from "never executed", which is the distinction the floor is
about. Worth revisiting.
