---
name: kavanara-secured
description: Enforces the KavanaraOrg security gates — a dependency vulnerability scan, a secret scan and security static analysis (SAST) in every build — and a red-team pass before every release that adds or changes a trust boundary. ALWAYS consult before adding or upgrading a dependency, suppressing or accepting a security finding, touching authentication, authorisation, tenant isolation, file handling, an external integration or an LLM/agent feature, preparing a release, or claiming a change is secure. Covers the severity threshold, why accepted findings expire, what a trust boundary is, who may red-team, prompt injection, and what the record must contain. Keywords: security, vulnerability, CVE, dependency scan, trivy, govulncheck, dependency-check, npm audit, secret, gitleaks, credential, token, SAST, semgrep, codeql, gosec, find-sec-bugs, red team, red-teaming, pentest, threat model, STRIDE, trust boundary, prompt injection, release.
---

# Secured

Full reasoning: `ADR-0005-security-gates-and-red-teaming`. The report-then-gate
rhythm and the reason-per-exclusion rule come from
`ADR-0004-coverage-floor-and-static-analysis`.

## The three gates

Every build, in CI:

| Gate | Fails the build on | Typical tool |
|---|---|---|
| Dependency scan | high/critical with a fix available | govulncheck, Trivy, OWASP Dependency-Check, npm audit |
| Secret scan | any finding, change and history | gitleaks |
| SAST | per rule set, after triage | gosec, Semgrep, CodeQL, find-sec-bugs |

The bug-pattern analyzer from ADR-0004 does not count as SAST unless its
security rule set is switched on and named. Be able to say which rules cover
security.

A new gate starts as a report. Triage, then arm it, and write the arming date
next to the gate while it is still a report.

## A secret in the repository

Rotate first, then remove. Rewriting history without rotating only hides that
the secret leaked, and anyone who cloned in between still has it. Tell the user
before anything else. This is not a cleanup to do quietly.

## Accepting a finding

When a finding is accepted instead of fixed, put three things next to the
suppression: **reason, owner, expiry date**. No expiry, no acceptance. A
vulnerability's risk changes when an exploit or a fix appears, and an
acceptance without an expiry is never looked at again.

Lowering a threshold to turn a build green is not an acceptance. It switches
the gate off for everyone.

## Red-teaming

Required before a release that adds or changes a **trust boundary**: any point
where input from a less-trusted party is acted upon. That includes an API
endpoint, authn/authz, tenant isolation, file or archive handling, a new
external integration, and an LLM or agent that reads content it did not write.

1. Write a short threat model: what is protected, who attacks, through which
   entry points. STRIDE is enough.
2. Attack it. Not the author alone. If you wrote the change in this session, you
   are the author, so a separate session or a human does the pass.
3. For LLM/agent features, always try prompt injection (instructions hidden in
   data the model reads), tool misuse, and exfiltration through tool output.
4. Record it under `docs/security/`: each attack tried, its outcome, each finding
   with its fix or an expiring acceptance. "No findings" still lists the
   attempts.
5. Each fixed finding gets a regression test (ADR-0002).

A release that touches no trust boundary needs no pass. Say so in the release
notes, so someone can disagree.

## Reporting

"Trivy: 0 high/critical, 3 medium triaged in `docs/security/accepted.md`" can be
checked. "No security issues" cannot. Never claim a change is secure. Say what
was checked, with what, and what was found.
