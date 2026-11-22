# ADR-0006: Large projects must build, start and pass their checks as containers

**Status:** Accepted
**Date:** 2026-09-27
**Scope:** KavanaraOrg repositories that qualify as *large* (defined below)
**Applies to:** humans and agents alike
**Builds on:** ADR-0005 (the image is scanned like any other dependency set)

## Context

Tessera and circlead-platform are not tools someone runs once; they are
services with a database, several deployable modules and external integrations.
Whether they run anywhere except the machine they were developed on is
currently a matter of luck, not of a check.

circlead-platform has a `docker/Dockerfile` and a `docker-compose.yml`, which is
the right start. But the image is built with `-DskipTests`, no CI job builds it,
and nothing proves the container actually starts and becomes healthy. A
Dockerfile nobody builds in CI rots silently: the next module added to the
reactor is missing from its `COPY` list, and nobody notices until a deployment.

limen, by contrast, is a single static binary. A container adds nothing but a
layer between the user and `limen`. A rule that forced it into Docker would be
ceremony.

## Decision

**A large project can be built, started and smoke-tested as a container, and
CI proves it on every change to the default branch.**

### What counts as large

A repository is large if **any** of these holds:

- it runs as a long-lived service (a server, a worker, a gateway), or
- it has more than one deployable module, or
- it needs another running service to work (a database, a message broker, a
  vault).

Tessera and circlead-platform are large. A CLI, a library, a plugin package, or
a static site is not. A repository declares which one it is in its README, so
nobody has to reconstruct the decision.

### What a large project provides

1. **A Dockerfile that builds from a clean checkout** with no host state: no
   pre-built artefacts copied in, no files outside the build context.
   Multi-stage, so the runtime image carries no compiler or build cache.
2. **A compose file** that starts the service together with the services it
   depends on, with no manual step between `docker compose up` and a working
   system.
3. **A health endpoint** wired to `HEALTHCHECK` (or the compose equivalent), and
   the service reads its configuration from environment variables or mounted
   files, never from values baked into the image.
4. **A non-root runtime user** and a pinned base image (tag plus digest, or at
   least a specific version tag, never `latest`).
5. **Secrets from outside the image.** No credential is ever present in any
   layer, including an intermediate one.

### What CI proves

On every change to the default branch, CI:

1. builds the image from the Dockerfile,
2. scans it for known vulnerabilities under ADR-0005's thresholds (the base
   image is a dependency like any other),
3. starts it with its compose file, waits for the health check to pass, and
   runs a smoke test against it: at least one real request through the public
   entry point.

The image build does not skip the test suite unless the same pipeline has
already run it against the same commit. `-DskipTests` in a Dockerfile is
acceptable only under that condition, and the Dockerfile says so next to the
flag.

## Consequences

- CI gets slower for large projects, by the time of one image build and one
  start. Layer caching limits most of it; the rest is the cost of knowing the
  artefact works.
- A module added without updating the Dockerfile now fails the build instead
  of the deployment.
- The "large" test means a small tool that grows into a service changes
  category. When it does, the README declaration changes and this ADR starts to
  apply. The first service-shaped change is the moment to add the Dockerfile,
  not the first deployment.
- Nothing here chooses an orchestrator. Kubernetes, a single VM running
  compose, or a PaaS all accept an image that builds, starts and reports
  healthy.

## Alternatives considered

**Containers for every repository.** Adds a layer to single binaries and
libraries without adding portability they lack. limen is easier to install
without Docker than with it.

**A Dockerfile without the CI proof.** This is circlead's current state, and it
shows why that is not enough: an unbuilt Dockerfile gives the appearance of
portability without proving any.

**Decide "large" by size in lines of code.** Size does not create the need for a
container; running as a service with dependencies does. A 200 000-line library
still ships as a library.
