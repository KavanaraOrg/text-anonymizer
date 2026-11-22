# ADR-0009: Credentials live in Bitwarden Secrets Manager, one project per repository

**Status:** Accepted
**Date:** 2026-11-06
**Scope:** All KavanaraOrg repositories
**Applies to:** humans and agents alike
**Builds on:** ADR-0005 (the secret scan keeps values out of the repository; a leaked value is rotated first)

## Context

ADR-0005 makes sure no secret value is committed. It does not say where a value
lives instead, so every repository answers that differently: a `.env` on one
laptop, a GitHub Actions secret, a note, a value copied from another project.

That fails in predictable ways. A new machine cannot run the project until
someone remembers which values it needs and where they came from. A value
rotated in one place keeps working in its copies, or stops working in places
nobody knew used it. An agent asked to run a command finds no value and is
tempted to invent a placeholder or look for one. Nobody can say which secrets a
repository needs without reading its code.

One store with a fixed shape answers all of that: where a value is, who owns
it, which repository reads it, and what to do when it is missing.

## Decision

**Every credential and secret of a repository lives in Bitwarden Secrets
Manager (BWS), in one BWS project per repository, named exactly like the
repository.**

1. **What counts.** Anything that grants access or decrypts: API keys, tokens,
   passwords, client secrets, licence keys, signing and encryption keys,
   connection strings with credentials. URLs, ports and switches are not
   secret; they are repository configuration and stay out of BWS.
2. **One project per repository.** The BWS project is named like the
   repository without the organisation (`circlead-platform`, `nuncio`). A
   repository has exactly one project; a project belongs to exactly one
   repository.
3. **Key = environment variable name.** A secret's key is the name of the
   environment variable the code reads (`ANTHROPIC_API_KEY`), so the store, the
   code and the inventory use one name.
4. **One owner, no copies.** A secret several repositories use lives once, in
   the project of the repository that owns it; the others are given read
   access. A value is never copied into a second project, so a rotation happens
   in one place.
5. **Code reads the environment.** Code reads environment variables, or a file
   the runtime mounts, never a committed file. Locally a command runs under
   `bws run --project-id <id> -- <command>`. A tool that insists on a `.env`
   may get a generated one: git-ignored, holding nothing that is not in BWS.
6. **Machines read, people write.** CI and deployed services fetch with
   `bitwarden/sm-action` or the BWS SDK through a machine account that can read
   only its own project. Creating, changing and rotating a value is done by a
   person.
7. **One bootstrap secret.** The BWS access token is the only secret outside
   BWS: in the OS keychain on a workstation, in the CI secret store in a
   pipeline. It is never in the repository and never in a `.env` of it.
8. **A committed inventory.** `docs/security/vault-inventory.md` names the BWS
   project and lists one row per key with purpose and owner, never a value. The
   row is added in the same change that starts reading the secret. (The file
   name avoids the words secret, credential and token on purpose: agent file
   guards block such names, and the inventory must be writable by an agent.)

### Agents

An agent never reads, prints, logs or commits a secret value and refers to a
secret only by its key. It does not run `bws secret get` or `bws secret list`
to look at values; `bws run` for a command the user asked for is fine when the
output does not echo the value. A secret that is needed and does not exist is
reported by key and BWS project, and the user creates it. No placeholder value,
no other storage.

### A leaked secret

A value found in the repository, a log or a tracked `.env` is rotated first, in
BWS, and only then removed from where it leaked (ADR-0005). Removing it without
rotating leaves a working value in the history.

## Consequences

- Setting a repository up on a new machine needs one thing: the BWS access
  token. Everything else follows from the project and the inventory.
- A rotation is one change in one place, and the inventory shows which
  repositories read the value.
- Every repository needs a BWS project and a machine account before its CI can
  read a secret. That is a few minutes per repository, once.
- BWS becomes a dependency of every build that needs a secret. An outage of BWS
  blocks those builds; it does not expose anything.
- Existing values in `.env` files and GitHub Actions secrets are moved into BWS
  repository by repository. Until a repository has moved, its inventory says
  so.

## Alternatives considered

**`.env` files per developer.** No setup, but values drift between machines,
nobody knows who has which, and a rotation never reaches every copy.

**GitHub Actions secrets only.** Fine for CI, useless on a workstation, and a
value shared by two repositories is copied into both.

**A cloud provider's secret manager.** Ties every repository to one cloud,
including those that do not run there, and needs a cloud identity on every
workstation.

**HashiCorp Vault.** More capable, but a server to run and secure for a team
that needs a store, not a platform.

**One BWS project for all repositories.** Simpler to set up, but every machine
account could read every value, and nothing tells which repository needs which
secret.
