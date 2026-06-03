---
name: referenta-contribution
description: Referenta's contribution workflow — ties Linear tickets (REF-N) to git branches, commits, and PRs and follows the team git rules. Use whenever doing fix/feature/chore work in a Referenta repo, especially when the user says "let's fix REF-123", "let's do REF-N", "work on this ticket", or asks to branch, commit, or open a PR for Referenta work. Also trigger when the user starts a fix or feature that probably needs a Linear ticket, even if they haven't named a REF-N yet.
---

# Referenta contribution workflow

Contributing a fix or feature to a Referenta repo means keeping the work tied to
a Linear ticket (`REF-N`) and following the team git conventions. The git rules
are the same as the global `~/.claude/CLAUDE.md` workflow — this skill adds
Referenta's Linear linkage and `REF-N` tagging on top, so honor both.

## Start from the Linear ticket

Referenta work is ticket-driven. Resolve the ticket *before* writing code, so the
branch, commits, and PR all reference it and the scope is agreed up front. Use the
Linear MCP tools (from the `linear` plugin) to read and create issues. If the
plugin isn't connected, ask the user to authenticate it rather than guessing
ticket details.

- **User names a ticket** ("let's fix REF-123", "let's do REF-123"): fetch it from
  Linear. Read the title, description, and acceptance criteria; reply with a
  one-line summary of your understanding and confirm scope before coding. Use the
  ticket title to derive the branch slug and PR title.
- **A fix or feature with no ticket named:** ask the user whether it's tracked in
  Linear. If it is, get the `REF-N`. If it isn't, offer to create one — and once
  they agree, create it via Linear with a clear, concise title and a description
  that states *what* is changing and *why* (plus scope/acceptance if known).
  Creating a ticket is outward-facing, so confirm the title and description with
  the user before creating it.
- **Trivial chores/docs** (a typo, formatting, a comment) don't need a ticket —
  use judgment. The "ask about Linear" step is specifically for fix/feature work.

Keep every description — Linear ticket, PR, commit body — clear and concise.
Clarity first: short, but never vague about what the change does.

## Branch

Branch off the base (`dev` if the repo has one, otherwise `main`), following the
once-per-session branch rule in `~/.claude/CLAUDE.md` (ask whether to branch out
or commit directly). Name it with the Conventional Commits type plus the ticket:

```
<type>/REF-N-short-kebab-description
# feat/REF-123-add-login    fix/REF-451-null-session    chore/REF-88-bump-deps
```

`<type>` is the type for the work: `feat`, `fix`, `chore`, `docs`, `refactor`,
`test`.

## Commit

Conventional Commits, with the ticket appended to the subject so history links
back to Linear:

```
<type>(scope): imperative subject (REF-N)
# feat(auth): add login form (REF-123)
# fix(session): handle null token (REF-451)
```

`scope` is optional. Keep the subject concise; add a body only when the "why"
isn't obvious from the subject. No attribution trailers (no "Generated with
Claude Code", no `Co-Authored-By`).

## Pull request

Don't push straight to `dev`/`main` — integrate through a PR (per CLAUDE.md). Open
it against the base branch:

- **Title:** `<type>: subject (REF-N)` — same shape as the commit subject.
- **Body:** concise. What changed and why, and a reference to the Linear ticket
  (`REF-N`) so the two stay linked. No filler.

## Code style

Only write comments that are relevant, informative, and necessary — comment the
non-obvious *why*, never restate what the code already says (same as CLAUDE.md).

## Example

> **User:** "let's do REF-204"

1. Fetch REF-204 from Linear → *"Add rate limiting to the public API."* Summarize
   the scope back and confirm.
2. Branch `feat/REF-204-public-api-rate-limit` off `dev`.
3. Commit `feat(api): add token-bucket rate limiter (REF-204)`.
4. PR into `dev` — title `feat: add public API rate limiting (REF-204)`, body
   summarizes the change and references REF-204.

> **User:** "let's fix the flaky checkout test"  *(no ticket named)*

1. Ask: "Is this in Linear?" → user says no.
2. Offer to create a ticket; on approval, create REF-N in Linear with a clear
   title + concise description, then proceed from step 2 of the example above.
