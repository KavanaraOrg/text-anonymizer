---
name: kavanara-containerised
description: Enforces that large KavanaraOrg projects (long-lived services, multiple deployable modules, or dependent on another running service — e.g. Tessera, circlead-platform) build, start and pass a smoke test as containers, proven by CI on every change to the default branch. ALWAYS consult before adding a module, a service dependency or a configuration value to such a project, editing its Dockerfile or compose file, deciding whether a repository counts as large, or claiming it is deployable. Keywords: docker, dockerfile, container, image, compose, docker-compose, healthcheck, health endpoint, smoke test, deploy, deployable, portable, base image, non-root, multi-stage, skipTests, large project, service, tessera, circlead.
---

# Containerised

Full reasoning: `ADR-0006-large-projects-ship-as-containers`. The image scan
thresholds come from `ADR-0005-security-gates-and-red-teaming`.

## Does it apply?

A repository is **large** if any holds: it runs as a long-lived service; it has
more than one deployable module; it needs another running service (database,
broker, vault). Size in lines does not matter.

Tessera and circlead-platform: large. A CLI like limen, a library, a plugin
package, a static site: not. The README states which one applies. If it is
missing, ask. Do not guess.

## What must exist

- A multi-stage **Dockerfile** that builds from a clean checkout. No host
  artefacts, nothing outside the build context, no compiler in the runtime image.
- A **compose file**: `docker compose up` alone yields a working system,
  dependencies included.
- A **health endpoint** behind `HEALTHCHECK`.
- Config from environment or mounted files. **Secrets never in any layer**,
  intermediate ones included.
- A **non-root** runtime user and a **pinned** base image, never `latest`.

## What CI proves

On every change to the default branch: build the image, scan it (ADR-0005),
start it with compose, wait for healthy, and send at least one real request
through the public entry point.

## The edits that break this quietly

- **Adding a module:** update the Dockerfile's `COPY` list and the compose file
  in the same change. The CI proof exists to catch the one you forget.
- **Adding a config value:** it comes from the environment, and the compose file
  gets a working default or a documented required variable.
- **`-DskipTests` (or equivalent) in the Dockerfile:** allowed only if the same
  pipeline already ran the tests on the same commit, and the Dockerfile says so
  next to the flag.

## Reporting

"Deployable" means the CI job built, started and smoke-tested the image on this
commit. Name the run. A Dockerfile that exists but has not been built proves
nothing.
