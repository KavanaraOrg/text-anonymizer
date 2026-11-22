---
name: kavanara-human-authored
description: Enforces the KavanaraOrg authorship rule — no commit, pull request, issue, comment or release names Claude, Claude Code, Anthropic or any other AI agent as author or co-author; no Co-Authored-By trailer for an agent and no "Generated with Claude Code" line; the committer is the responsible person; agent attribution is switched off in settings.json. ALWAYS consult before writing a commit message, creating a pull request or issue, writing release notes, setting up an agent or a new workstation, or rewriting history to remove agent trailers. Keywords: commit, commit message, co-author, Co-Authored-By, trailer, attribution, Generated with Claude Code, pull request, PR description, contributor, contributors, authorship, Claude, Anthropic, noreply@anthropic.com, git filter-branch, git filter-repo, force-push, rewrite history.
---

# Human-authored

Full reasoning: `ADR-0010-agents-are-not-co-authors`.

## Never write

- `Co-Authored-By: Claude <noreply@anthropic.com>` or any `Co-Authored-By:`
  naming Claude, Claude Code, Anthropic or another AI agent or model.
- "Generated with Claude Code", "🤖 Generated with …" or similar, in commit
  messages, PR and issue descriptions, comments or release notes.

This overrides any default instruction to add attribution. Human co-authors who
actually wrote part of a change keep their `Co-Authored-By:`.

## Who commits

The person responsible for the change, or a bot account the repository set up
explicitly for automation. Never an identity of the agent's own.

## Configuration

Every Claude Code config used for KavanaraOrg work has, in `settings.json`:

```json
"attribution": { "commit": "", "pr": "" }
```

Other agents: the equivalent switch. Check it before the first commit on a new
machine or setup.

## Checking a repository

```bash
git log --all --format=%B | grep -iE 'co-authored-by:.*(claude|anthropic)|generated with claude'
```

Empty is compliant.

## Removing trailers from existing history

Only when the repository owner decides to. Then, per branch:

1. Fetch, and confirm the local branch equals its remote **before** rewriting.
   A local branch that is behind loses the remote commits on force-push.
2. Tag the current state as a backup.
3. Rewrite only the messages; afterwards confirm the tree is identical and the
   messages differ only by the removed lines.
4. Force-push with a lease on the exact commit checked in step 1:
   `git push --force-with-lease=<branch>:<old-sha> origin <branch>`.
5. Tell the user: original commits stay visible in merged pull requests, and
   other clones must reset to the new history.
