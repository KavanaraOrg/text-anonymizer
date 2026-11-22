# ADR-0010: AI agents are not co-authors

**Status:** Accepted
**Date:** 2026-11-22
**Scope:** All KavanaraOrg repositories
**Applies to:** humans and agents alike

## Context

Claude Code, like other coding agents, appends attribution to the work it helps
produce: a `Co-Authored-By: Claude <noreply@anthropic.com>` trailer on commits
and a "Generated with Claude Code" line in pull request descriptions. GitHub
reads the trailer and lists the agent as a contributor to the repository and as
a co-author on every commit that carries it.

That attribution says something untrue about responsibility. An agent is a
tool. The person who asked for the change, reviewed it and committed it
answers for it, as they would for code produced with any other tool. A
contributor list that names a tool blurs who answers for the code.

Once a trailer is pushed, removing it means rewriting history: every hash
changes, branches have to be force-pushed, and the original commits survive in
merged pull requests where only GitHub support can purge them. Removing the
trailers from limen, text-anonymizer and nuncio in November 2026 showed what
this costs, including a merged pull request that a careless force-push briefly
dropped from `main`. Never writing the trailer costs nothing.

## Decision

**No commit, pull request, issue or release in a KavanaraOrg repository names
an AI agent as author or co-author, or carries a line attributing it to one.**

1. **No agent trailers.** No `Co-Authored-By:` trailer naming Claude, Claude
   Code, Anthropic or any other AI agent or model (`Co-Authored-By: Claude
   <noreply@anthropic.com>` and its variants).
2. **No generated-by lines.** No "Generated with Claude Code", "🤖 Generated
   with …" or similar line in commit messages, pull request or issue
   descriptions, comments or release notes.
3. **The committer is a person.** Author and committer of every commit are the
   person responsible for it, or a bot account the repository has explicitly
   set up for automation (e.g. a release bot). An AI agent never commits under
   an identity of its own.
4. **Switched off at the source.** Every Claude Code configuration used for
   KavanaraOrg work disables attribution in its `settings.json`:

   ```json
   "attribution": { "commit": "", "pr": "" }
   ```

   Other agents are configured the equivalent way.
5. **Checkable.** For a repository's history this has to come back empty:

   ```bash
   git log --all --format=%B | grep -iE 'co-authored-by:.*(claude|anthropic)|generated with claude'
   ```

6. **Human co-authors stay.** `Co-Authored-By:` for people who actually wrote
   part of a change is welcome. The rule is about tools, not about the trailer.

### Agents

An agent writing a commit message, pull request description, issue or comment
leaves out any attribution to itself, even when its own default instructions
say to add one. This ADR is the instruction that takes precedence.

### Existing history

Commits pushed before this ADR may still carry agent trailers. Removing them
rewrites history and is only done when the repository owner decides to. When
it is done, every branch is checked to match its remote before it is rewritten,
the force-push is leased against the exact commit that was checked, and the
result is checked to differ from the original in nothing but the removed lines.

## Consequences

- A repository's contributor list on GitHub shows only people and declared
  bots.
- Whether and how far an agent helped with a change is no longer visible in the
  history. If a project wants to record that, it does so in its own
  documentation, not in authorship.
- A new workstation or a new agent setup needs the attribution switch set
  before its first commit. A trailer that slips through stays in the history
  unless someone rewrites it.

## Alternatives considered

**Keep the agents' default attribution.** Transparent about tool use, but it
makes a tool a contributor and attributes authorship where there is no
responsibility.

**Remove trailers periodically by rewriting history.** Every pass changes
hashes, force-pushes shared branches and still leaves the original commits in
merged pull requests. Preventing the trailer is cheaper than removing it.

**A neutral trailer such as `Assisted-by:`.** GitHub does not list it as a
contributor, but it still records a tool in the authorship metadata, and no
other tool used on a change gets such a line.
