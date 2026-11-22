# ADR-0008: Every build produces an SBOM, and every component allows commercial use

**Status:** Accepted
**Date:** 2026-10-24
**Scope:** All KavanaraOrg repositories
**Applies to:** humans and agents alike
**Builds on:** ADR-0004 (report first, then gate; every exclusion carries its reason), ADR-0005 (the dependency scan reads the same inventory)

## Context

ADR-0005 checks resolved dependencies for known vulnerabilities. It does not say
what those dependencies are, so nobody downstream can check, and it says nothing
about whether we are allowed to use them.

Both questions come up as soon as a product is sold, hosted for a customer or
handed to an auditor. A customer asks which components a release contains, and
a vulnerability published next month has to be traced to the releases that ship
it. The EU Cyber Resilience Act turns that inventory into an obligation for
products placed on the market. Without a software bill of materials (SBOM) for
each release, the answer is rebuilt from memory.

The licence question is worse because it fails silently. A transitive
dependency under AGPL, SSPL or a non-commercial clause builds and tests like any
other. Nothing goes red until someone reads the licence, often during a sale or
a due diligence, when replacing the component is most expensive. Licences also
change between versions: several widely used projects moved from a permissive
licence to BUSL or SSPL in a minor release, so a routine upgrade can make a
product unsellable.

The state is uneven. Tessera generates CycloneDX SBOMs for backend and UI and
runs a licence gate in CI. fundus generates a CycloneDX aggregate BOM but checks
no licences and has no licence file of its own. circlead-platform does neither.

## Decision

**Every build produces an SBOM, and a licence gate keeps every shipped
component usable commercially.**

### The SBOM

1. **Format.** CycloneDX JSON (`*.cdx.json`). SPDX is accepted where an
   ecosystem only produces SPDX. One format across repositories means one tool
   can read all of them.
2. **Coverage.** Everything that ships: every build ecosystem in the repository
   (e.g. Maven *and* npm for a backend with a UI) and, for a container, the
   image including its base layers (ADR-0006). A repository with two ecosystems
   produces both SBOMs or a merged one. It does not produce one SBOM and call
   that covered.
3. **Content.** Each component carries name, version, a package URL (`purl`)
   and its declared licence as an SPDX identifier or expression.
4. **When.** Generated in CI on every build and kept as a build artefact. On a
   release it is attached to the release and to the published image, so the
   SBOM for any shipped version can be retrieved later without rebuilding it.

### Commercial use

The repository's own licence must allow commercial use. Every repository has a
`LICENSE` file. Apache-2.0 is the default; another licence is a decision recorded
in the repository.

Every component in the SBOM is classified from its declared licence:

| Class | Examples | Gate |
|---|---|---|
| **Permitted** | Apache-2.0, MIT, BSD, ISC, Zlib, 0BSD, Unlicense, CC0, Python, PostgreSQL, UPL, BlueOak | passes |
| **Weak copyleft** | LGPL, MPL-2.0, EPL-2.0, CDDL, GPL with Classpath Exception | passes when used unmodified as a library; a modification of the component itself is a recorded decision |
| **Strong copyleft** | GPL, AGPL, EUPL, OSL | fails |
| **Not for commercial use** | SSPL, BUSL, Elastic License, Commons Clause, PolyForm, any *NonCommercial* or CC-BY-NC/-ND clause | fails |
| **Unknown** | no licence declared, unrecognised text | fails |

A component that is dual-licensed passes when one of its licences is permitted,
and the SBOM or the exception file records which licence we use.

Unknown fails because a component without a licence is not free to use. Without
a licence, all rights stay with the author.

The table applies to what the product is **built from**: the dependencies it
links, bundles or loads (Maven, npm, Go modules and the like) and the assets it
ships. A container image also carries **separate programs**: the operating-system
packages of its base image, and unmodified third-party programs that run as
their own process next to ours (a database server, a monitoring agent). Shipping
those is aggregation. A GPL licence on `bash` in a base image obliges us to make
its source available; it does not reach our code. Separate programs are
therefore listed in the image SBOM but not gated by the copyleft classes. They
still fail when their licence forbids commercial use or hosting (SSPL, BUSL and
the rest of that row), because that restriction holds however the program is
run. A modified separate program, or one our code links against, is a
dependency and is gated as one.

The rule covers everything that ships, not only code: AI model weights,
datasets, fonts, icons and images. Model licences in particular often restrict
commercial use or user numbers, and they rarely appear in a package manager.
Such assets are listed in the SBOM by hand when no tool finds them.

### Exceptions

A failing component that is used anyway is an exception with a **reason, an
owner, and the exact component version** it covers, in one committed file
(e.g. `docs/security/licence-exceptions.md`). The exception lapses on any
version change of that component, so an upgrade is reviewed again. That is what
catches a relicence in a minor release.

A component used only at build or test time and never shipped (a test runner,
a code generator whose output carries no licence) may be excluded from the gate.
The exclusion is scoped to that dependency scope and carries its reason, as in
ADR-0004.

### Rhythm

As in ADR-0004 and ADR-0005: the first run is a report and gets triaged, then
the gate is armed. A repository that has not yet armed it records the arming
date next to the gate.

## Consequences

- A component can be rejected for its licence alone, however good it is. That
  costs time when choosing dependencies and saves far more at the point of sale.
- Licence metadata in package registries is often missing or wrong, so the
  first triage produces work: looking up the actual licence and recording it.
  A recorded correction carries its source.
- An upgrade can fail the build because the licence changed. That is the gate
  working, and the answer is to pin, replace or decide, not to loosen the list.
- Release artefacts grow by a few SBOM files. They are what lets a vulnerability
  published after the release be mapped to the versions that ship it.
- This is not legal advice and does not replace one. It removes the clear cases
  automatically so that the unclear ones reach a person.

## Alternatives considered

**SBOM only on release.** Cheaper, but a licence problem then appears at the
moment a release is wanted. Building it every time costs seconds and keeps the
gate on every change.

**A licence denylist only.** A denylist misses every licence nobody thought of.
The table above fails unknown licences, so a new one has to be classified before
it ships.

**Allow strong copyleft for internal or network-only use.** Defensible in a
single case, but AGPL applies to network use, and "internal" changes as soon as
a customer hosts the software. Such cases are exceptions with a reason, not a
default.

**Leave it to a periodic legal review.** A yearly review finds a component that
has shipped in every release since it was added. The gate stops it in the
change that adds it.
