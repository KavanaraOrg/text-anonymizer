---
name: kavanara-vaulted
description: Enforces the KavanaraOrg secrets rule — every credential and secret of a repository lives in Bitwarden Secrets Manager (BWS), in one BWS project per repository named exactly like the repository, with the environment variable name as the key; code reads the environment, commands run under bws run, CI fetches with a read-only machine account, and docs/security/vault-inventory.md lists the keys without values. ALWAYS consult before adding, reading, rotating or moving a credential, API key, token, password, licence key or encryption key, writing or changing a .env file, adding a CI step or deployment that needs a secret, setting a repository up on a new machine, or when a secret is missing or leaked. Keywords: secret, credential, API key, token, password, Passwort, Zugangsdaten, .env, environment variable, Bitwarden, Bitwarden Secrets Manager, bws, bws run, BWS_ACCESS_TOKEN, machine account, sm-action, GitHub Actions secret, keychain, rotation, leaked secret, Secret Manager, Vault.
---

# Vaulted

Full reasoning: `ADR-0009-one-bitwarden-vault-per-repository`. The secret
scan that keeps values out of the repository is `ADR-0005-security-gates-and-red-teaming`.

## Where a secret lives

- **Bitwarden Secrets Manager**, one **project per repository**, named exactly
  like the repository without the organisation: `circlead-platform`, `nuncio`.
- **Key = environment variable name** the code reads (`ANTHROPIC_API_KEY`).
- A secret several repositories use lives once, in the owning repository's
  project; the others get read access. Never copy a value into a second project.
- Not secret (URLs, ports, switches): repository configuration, not BWS.

## How code and commands get it

- Code reads environment variables (or a file the runtime mounts). Never a
  committed file.
- Locally: `bws run --project-id <id> -- <command>`.
- A generated `.env` is allowed for tools that need one: git-ignored, nothing in
  it that is not in BWS.
- CI: `bitwarden/sm-action` with a machine account that can **read only its
  project**. People write, machines read.
- The BWS access token is the only secret outside BWS: OS keychain on a
  workstation, CI secret store in a pipeline. Never in the repository, never in
  a `.env` of it.

## The inventory

`docs/security/vault-inventory.md` in every repository: the BWS project name and one row
per key with purpose and owner, **no values**. Add the row in the same change
that starts reading a new secret.

## As an agent

- Never read, print, log or commit a secret value. Refer to it by key.
- A needed secret that does not exist: name the key and the BWS project and ask
  the user to create it. No placeholder values, no other storage.
- Do not run `bws secret get` or `bws secret list` to look at values. `bws run`
  for a command the user asked for is fine; its output must not echo the value.
- Found a secret in the repository, a log or a `.env` that is tracked: stop and
  tell the user. It is rotated first, in BWS, then removed (ADR-0005).

## Reporting

"Needs `NUNCIO_API_KEY` in BWS project `circlead-platform` (not there yet);
added the row to `docs/security/vault-inventory.md`" can be acted on. "Set the API key
somewhere" cannot.
