# ADR-0005: Security gates in every build, red-teaming before every release

**Status:** Accepted
**Date:** 2026-09-27
**Scope:** All KavanaraOrg repositories
**Applies to:** humans and agents alike
**Builds on:** ADR-0004 (report first, then gate; every exclusion carries its reason)

## Context

ADR-0004 added two quality gates, coverage and a bug-pattern analyzer. Both
answer the question *does the code do what it is meant to do?* Neither answers
*what can someone who wants it to misbehave make it do?*

A bug-pattern analyzer finds null paths and races. It does not know that a
transitive dependency has a published CVE, that a token was committed in a test
fixture three months ago, or that a query is assembled from request input. Those
are different classes of defect with different tools, and none of them is
covered today.

circlead-platform shows the gap. Its `verify` phase runs SpotBugs, PMD,
Checkstyle and JaCoCo, which is the ADR-0004 state done properly. Nothing in its
CI scans dependencies for known vulnerabilities, scans history for secrets, or
runs a security-focused static analysis. It holds tenant data, an MCP server and
an agent handler: three trust boundaries, none of them tested from the
attacker's side.

Scanners find *known* weakness classes. They do not find a design that lets a
low-privilege tenant read another tenant's data by composing two legitimate
calls, or an agent tool that follows instructions embedded in a document it was
asked to summarise. Such flaws only turn up when someone deliberately attacks the
system, and nothing obliges anyone to do that.

## Decision

**Three automated security gates in every build, and a red-team pass before
every release that changes a trust boundary.**

### Automated gates

Every repository runs, in CI, on every change:

1. **Dependency vulnerability scan.** Resolved dependencies are checked against
   a vulnerability database (e.g. `govulncheck` for Go, OWASP
   Dependency-Check or Trivy for the JVM, `npm audit` or Trivy for Node).
   A finding of severity **high or critical** with a fix available fails the
   build.

2. **Secret scan.** The change and the repository history are scanned for
   committed credentials (e.g. gitleaks). Any finding fails the build. A leaked
   secret is rotated first, then removed. Removing it from history without
   rotating it only hides that it leaked.

3. **Security static analysis (SAST).** A security-rule analyzer reads the
   sources for injection, unsafe deserialisation, path traversal, weak crypto
   and similar classes (e.g. `gosec`, Semgrep, CodeQL, find-sec-bugs as a
   SpotBugs plugin). This is distinct from ADR-0004's bug-pattern analyzer even
   when one tool can do both: a repository must be able to say which rule set
   covers security.

All three follow ADR-0004's rhythm: a first run is a report and gets triaged,
then the gate is armed. A repository that has not yet armed a gate records that
state and the date it will be armed, in the same file as the gate.

### Accepted findings

A finding that is accepted instead of fixed carries its reason, its owner and
an **expiry date** next to the suppression. Unlike an analyzer exclusion, a
vulnerability's risk changes over time: an exploit is published, or the fix
becomes available. An acceptance without an expiry never gets reviewed again.

### Red-teaming

Before a release that **adds or changes a trust boundary**, someone
deliberately attacks the change and records what they tried. A trust boundary
is any point where input from a less-trusted party is acted upon: an API
endpoint, authentication or authorisation logic, tenant isolation, file or
archive handling, a new external integration, or an LLM or agent that reads
content it did not author.

- The pass works from a short **threat model** of the change: what it
  protects, who might attack it, and through which entry points. STRIDE is
  enough.
- It may be done by a human or an agent, but not by the author of the change
  acting alone. The author knows what the code is meant to do, and that is
  exactly the bias the pass exists to remove.
- For LLM and agent features it explicitly covers **prompt injection**
  (instructions hidden in data the model reads), tool misuse, and data
  exfiltration through tool output.
- The result is a record under `docs/security/`, listing each attack tried,
  its outcome, and each finding with its fix or accepted-risk entry. A pass
  that found nothing still records what it tried. "Red-teamed, no findings"
  without the attempts is not evidence.
- Each finding that was fixed gets a regression test (ADR-0002), so the same
  attack is repeated on every later build.

A release that touches no trust boundary does not need a pass. Deciding that it
touches none is itself stated in the release notes, so someone can disagree.

## Consequences

- Three more ways for CI to be red. Dependency scans are the noisy one: a CVE
  published overnight can redden a build nobody touched. That is the gate
  working, and the answer is to upgrade or record an expiring acceptance, not
  to loosen the threshold.
- The expiry on accepted findings creates recurring work. It is meant to.
- Red-teaming costs time at exactly the moment a release is wanted. Limiting it
  to trust-boundary changes keeps the cost proportional; a copy change does not
  need an attacker's review.
- An agent can do a useful red-team pass, which makes the requirement cheap
  enough to keep. It cannot be the same session that wrote the change.

## Alternatives considered

**Scanners only, no red-teaming.** Scanners find known weakness classes. The
flaws that cost most, such as broken authorisation logic, cross-tenant access,
or an agent obeying a document, are design flaws that no current scanner
recognises.

**A periodic external penetration test instead.** Valuable, and not excluded.
But a yearly test reviews a system that has changed many times since the last
one, while a pass per boundary change reviews the change while it is still
fresh.

**Fail on every severity.** Low and medium findings without a fix would keep
builds red with nothing actionable. They are reported and triaged, not gated.

**Red-team every release.** Makes the pass routine, and a routine pass tends
to repeat last time's checklist instead of attacking the new change.
