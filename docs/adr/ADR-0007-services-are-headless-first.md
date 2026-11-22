# ADR-0007: Services work headless — the frontend is one client among others

**Status:** Accepted
**Date:** 2026-09-27
**Scope:** KavanaraOrg repositories that run as a service (see ADR-0006, "large")
**Applies to:** humans and agents alike
**Builds on:** ADR-0006 (the smoke test goes through the public entry point)

## Context

A service with a web frontend tends to grow features that exist only in the
frontend: a validation rule written in the browser, a workflow step that is a
sequence of clicks with no single call behind it, an export that renders in the
page and has no endpoint. Each one is harmless alone. Together they mean the
service can no longer be operated, tested or automated without driving a
browser.

That matters more for KavanaraOrg than for most, because agents are first-class
users. An agent works through an API, a CLI or an MCP server. It does not click.
A capability that only the frontend has is a capability no agent, no script and
no other service can use, and one that can only be tested end to end through a
UI, which is the slowest and most brittle test there is.

## Decision

**Every capability of a service is available without its frontend. The
frontend is a client of the same public interface that everyone else uses, and
holds no rule that the service does not also enforce.**

### What this means

1. **Complete headless interface.** Everything a user can do in the frontend
   can be done through the service's public interface (an HTTP API, and where
   useful a CLI or MCP server on top of it), with the same permissions.
2. **No private frontend API.** The frontend calls the documented public
   interface. An endpoint that exists only for the frontend's convenience is
   either documented and public, or does not exist.
3. **Rules live in the service.** Validation, authorisation, calculations and
   state transitions are enforced by the service. The frontend may repeat a
   check for fast feedback; it is never the only place the check exists.
4. **The service runs without the frontend.** It starts, reports healthy and
   passes its smoke test with no frontend deployed. The frontend is a separate
   module or a separate artefact, never a precondition of the service.
5. **The interface is described.** A machine-readable contract (OpenAPI or
   equivalent) is committed and kept in sync, so a client can be written
   without reading the frontend's source.

### How it is proven

- The ADR-0006 smoke test and the service's integration tests exercise the
  public interface directly, not through a browser.
- A frontend feature is not done until its operation is covered by a test
  against the interface. UI tests may exist on top; they do not replace it.

## Consequences

- Features take one more step: the interface first, then the screen. The
  interface is usually the part that would have been written anyway.
- Agents, scripts and other services can use every capability from day one,
  without a scraping layer or a "please add an endpoint" ticket afterwards.
- Most behaviour becomes testable below the UI, which keeps the test suite fast
  and ADR-0002's failing-test-first practical for service work.
- A frontend can be replaced, or a second one added, without touching the
  service's rules.

## Alternatives considered

**Backend-for-frontend endpoints shaped per screen.** Convenient for the page,
but it creates exactly the private API this ADR forbids. If a screen needs an
aggregated view, that view is a public, documented resource.

**Let the UI tests prove the behaviour.** They prove the screen works, not that
the capability exists without it, and they are the slowest place to find a
broken rule.

**Apply it only when an agent needs the capability.** By then the rule sits in
the frontend and has to be moved, under time pressure, with no test pinning it.
Headless first costs less than headless later.
