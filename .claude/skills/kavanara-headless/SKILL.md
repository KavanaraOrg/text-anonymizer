---
name: kavanara-headless
description: Enforces that every KavanaraOrg service works headless — every capability reachable through its documented public interface (HTTP API, optionally CLI or MCP) without the frontend, the frontend a client of that same interface, and no rule that exists only in the frontend. ALWAYS consult before adding a feature, screen, form, button, validation or endpoint to a service, before writing frontend logic, before adding a backend-for-frontend route, and before claiming a service feature is done. Keywords: headless, API-first, API, REST, OpenAPI, endpoint, frontend, UI, web app, screen, form, validation, backend-for-frontend, BFF, CLI, MCP, agent, automation, integration test, service, tessera, circlead.
---

# Headless

Full reasoning: `ADR-0007-services-are-headless-first`. What counts as a
service comes from `ADR-0006-large-projects-ship-as-containers`.

## Does it apply?

To every repository that runs as a service. A CLI, a library or a static site
has no frontend to hide behind. If the README does not say, ask.

## The rule

Everything the frontend can do, the public interface can do, with the same
permissions. The frontend holds no rule the service does not enforce.

## Before writing a feature

1. Design the operation on the public interface first, and update the committed
   contract (OpenAPI or equivalent).
2. Write the failing test against the interface (ADR-0002), not against the UI.
3. Enforce validation, authorisation and state transitions in the service.
4. Only then build the screen, calling that same interface.

## The edits that break this quietly

- **Validation only in a form.** Repeat it in the frontend for feedback if you
  like; the service must reject the same input on its own.
- **A route only the frontend calls.** Document it and make it public, or fold
  it into an existing resource.
- **A workflow that is a sequence of clicks.** If the user thinks of it as one
  action, the interface offers it as one call.
- **Rendering data that has no endpoint** (an export, a report, a computed
  summary in the page). The data comes from the interface; the page only
  formats it.
- **The service needing the frontend to start.** It starts, reports healthy and
  passes its smoke test with no frontend deployed.

## Reporting

"Done" for a service feature means a test drives the operation through the
public interface and the contract is updated. A working screen alone proves
nothing about the service.
