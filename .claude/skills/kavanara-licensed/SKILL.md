---
name: kavanara-licensed
description: Enforces the KavanaraOrg supply-chain inventory and licence rule — every build produces a CycloneDX SBOM covering everything that ships, and a licence gate fails on any component that does not allow commercial use (strong copyleft, non-commercial or source-available, unknown). ALWAYS consult before adding, replacing or upgrading a dependency, model, dataset, font or other asset, adding a build ecosystem or container image, choosing or changing a repository's own licence, preparing a release, or accepting a licence exception. Covers SBOM format and coverage, the licence classes, dual licences, why exceptions are pinned to a version, and build-only exclusions. Keywords: SBOM, software bill of materials, CycloneDX, SPDX, purl, syft, cyclonedx-maven-plugin, npm sbom, licence, license, commercial use, kommerzielle Nutzung, GPL, AGPL, LGPL, MPL, SSPL, BUSL, Commons Clause, Elastic License, non-commercial, CC-BY-NC, Apache-2.0, MIT, relicence, model licence, Cyber Resilience Act, CRA, due diligence.
---

# Licensed

Full reasoning: `ADR-0008-sbom-and-commercial-use`. The report-then-gate rhythm
and the reason-per-exclusion rule come from
`ADR-0004-coverage-floor-and-static-analysis`; the dependency scan of
`ADR-0005-security-gates-and-red-teaming` reads the same inventory.

## The SBOM

- **CycloneDX JSON** (`*.cdx.json`); SPDX only where the ecosystem offers
  nothing else.
- **Everything that ships**: every build ecosystem in the repository, and for a
  container the image with its base layers. Maven plus npm means two SBOMs or
  one merged one, never just the backend.
- Each component: name, version, `purl`, licence as an SPDX identifier.
- Built in CI on **every build** and kept as an artefact; attached to every
  release and published image.

Typical tools: `cyclonedx-maven-plugin` (`makeAggregateBom`), `npm sbom
--sbom-format cyclonedx`, `cyclonedx-gomod`, `syft` for images.

## The licence gate

The repository itself has a `LICENSE` that allows commercial use; Apache-2.0
unless recorded otherwise.

| Class | Gate |
|---|---|
| Permitted: Apache, MIT, BSD, ISC, Zlib, 0BSD, Unlicense, CC0, Python, PostgreSQL, UPL | pass |
| Weak copyleft: LGPL, MPL, EPL, CDDL, GPL + Classpath Exception | pass when used unmodified as a library |
| Strong copyleft: GPL, AGPL, EUPL, OSL | **fail** |
| Not commercial: SSPL, BUSL, Elastic, Commons Clause, PolyForm, NonCommercial, CC-BY-NC/-ND | **fail** |
| Unknown / none declared | **fail**. No licence means all rights reserved |

Dual-licensed: passes if one licence is permitted; record which one we use.

The table gates what the product is **built from**: linked, bundled or loaded
dependencies and shipped assets. **Separate programs** in an image, such as
base-image OS packages or an unmodified database or agent running as its own
process, are aggregation. They are listed in the image SBOM and fail only on
the not-commercial row (SSPL, BUSL, …), not on GPL. Once modified or linked
against, they count as dependencies.

Tessera's `scripts/sbom.sh` is a working reference implementation (Maven + npm,
with a self-test of the gate).

## Not only code

Model weights, datasets, fonts, icons and images ship too and count. Model
licences often restrict commercial use or user numbers and appear in no package
manager. Read the licence before using the model, and add it to the SBOM by hand
if no tool finds it.

## Before adding or upgrading a dependency

Check its licence first, and on an upgrade check that it **did not change**.
A relicence to BUSL or SSPL in a minor release is the case this gate exists for.
Tell the user when a wanted component fails; do not quietly pick a substitute or
add an exception.

## Exceptions

A failing component used anyway: **reason, owner, exact version** in
`docs/security/licence-exceptions.md`. It lapses on any version change. Adding
an exception is the user's decision, not the agent's.

Build- and test-only dependencies that never ship may be excluded by scope, with
the reason next to the exclusion. Widening the permitted list to turn a build
green is not an exception; it switches the gate off.

## Reporting

"SBOM: 412 components (Maven 301, npm 111); licence gate clean, 1 exception
(`foo@2.3.1`, MPL modified, owner Matthias)" can be checked. "Licences are fine"
cannot. This is not legal advice. Unclear cases go to a person.
