---
name: kavanara-covered
description: Enforces the KavanaraOrg coverage floor (75% line coverage per module, as a ratchet where not yet met) and the requirement that every repository run a bug-pattern analyzer over its own sources. ALWAYS consult before changing a coverage threshold, adding or excluding a static-analysis rule, reporting coverage, or claiming a quality gate is satisfied. Explains why a floor is not a target, why it does not licence writing tests after the code, how the ratchet works, and why every exclusion needs a stated reason. Keywords: coverage, jacoco, line coverage, threshold, gate, ratchet, floor, 75, static analysis, spotbugs, analyzer, bug pattern, lint, exclusion, suppress, quality gate.
---

# Covered

Full reasoning: `ADR-0004-coverage-floor-and-static-analysis`. The loop that gets
you there is `ADR-0002-test-driven-development`.

## The floor

**75% line coverage per module.** Below that, treat the area as unexercised.

It is a floor, not a target. Do not optimise a module from 80% to 95%; that work
buys little and starts producing tests written for the metric. Do look hard at a
module in the forties.

## The ratchet

If a repository is below the floor, it does not declare 75% and leave the build
red. It records its **current lowest per-module ratio** as the enforced value,
in one named property, and raises it as coverage improves. Never lower it.

When you raise it, raise it to what is now measured — not to a round number you
hope to reach.

## What this does not licence

Coverage is still not a target, and this is still not permission to write tests
after the code. The route to the floor is ADR-0002's loop applied to the next
change in that area. If you find yourself writing a test whose purpose is to
move a percentage, you are writing the test ADR-0002 rejected.

When you report coverage, report the measurement and where it came from. "61.7%
overall, from the JaCoCo artifact of CI run 32647543964" is checkable;
"coverage is good" is not.

## The analyzer

Every repository runs a bug-pattern analyzer over its own sources. A formatter,
a dependency enforcer and architecture rules do not count — they check shape,
not behaviour inside a method.

Start it as a **report**, not a gate. A first run over an existing codebase
produces findings nobody has triaged; gating immediately reddens the build
without adding information. Triage, then arm it.

## Exclusions

Generated code is excluded. Everything else that is excluded carries its reason
in the same file, next to the exclusion.

An exclusion without a stated reason is indistinguishable from a defect someone
hid. If the reason is "this pattern is noise here", say what makes it noise and
what acting on it would cost — a reader six months later cannot reconstruct
that, and will either trust it blindly or undo it.

Suppressing a whole pattern is a policy decision and belongs in a commit message
that says so. Suppressing one site is a code review conversation.
