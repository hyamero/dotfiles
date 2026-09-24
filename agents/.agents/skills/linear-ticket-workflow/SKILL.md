---
name: linear-ticket-workflow
description: Ticket-driven contribution workflow for teams that track work in Linear — ties Linear issues (e.g. ABC-123) to git branches, commits, and PRs. Use whenever doing fix/feature/chore work in a repo whose team uses Linear, especially when the user says "let's fix ABC-123", "let's do ABC-N", "work on this ticket", or asks to branch, commit, or open a PR for ticketed work. Also trigger when the user starts a fix or feature that probably needs a Linear ticket, even if they haven't named one yet.
---

# Linear ticket workflow

Contributing a fix or feature means keeping the work tied to a Linear issue and
following the team's git conventions. The issue key (`<TEAM>-N`, e.g. `ABC-123`)
runs through the branch, commits, and PR so each links back to the ticket. Git
rules from the user's global instructions still apply — this skill adds the
Linear linkage on top, so honor both.

## Start from the ticket

Resolve the ticket *before* writing code, so the branch, commits, and PR all
reference it and the scope is agreed up front. Use the Linear MCP tools (from the
`linear` plugin) to read and create issues. If the plugin isn't connected, ask the
user to authenticate it rather than guessing ticket details.

- **User names a ticket** ("let's fix ABC-123"): fetch it from Linear. Read the
  title, description, and acceptance criteria; reply with a one-line summary of
  your understanding and confirm scope before coding. Use the ticket title to
  derive the branch slug and PR title.
- **A fix or feature with no ticket named:** ask the user whether it's tracked in
  Linear. If it is, get the key. If it isn't, offer to create one — and once they
  agree, create it with a clear, concise title and a description that states
  *what* is changing and *why* (plus scope/acceptance if known). Creating a ticket
  is outward-facing, so confirm the title and description before creating it.
- **Trivial chores/docs** (a typo, formatting, a comment) don't need a ticket —
  use judgment. The "ask about Linear" step is specifically for fix/feature work.

Keep every description — ticket, PR, commit body — clear and concise. Clarity
first: short, but never vague about what the change does.

## Branch

Branch off the base (`dev` if the repo has one, otherwise `main`), following any
branch rule in the user's global instructions. Name it with the Conventional
Commits type plus the ticket key:

```
<type>/<KEY>-short-kebab-description
# feat/ABC-123-add-login    fix/ABC-451-null-session    chore/ABC-88-bump-deps
```

`<type>` is the type for the work: `feat`, `fix`, `chore`, `docs`, `refactor`,
`test`.

## Commit

Conventional Commits, with the ticket key appended to the subject so history
links back to Linear:

```
<type>(scope): imperative subject (<KEY>)
# feat(auth): add login form (ABC-123)
# fix(session): handle null token (ABC-451)
```

`scope` is optional. Keep the subject concise; add a body only when the "why"
isn't obvious from the subject. No attribution trailers (no "Generated with
Claude Code", no `Co-Authored-By`).

## Pull request

Don't push straight to `dev`/`main` — integrate through a PR against the base
branch:

- **Title:** `<type>: subject (<KEY>)` — same shape as the commit subject.
- **Body:** concise. What changed and why, and a reference to the ticket key so
  the two stay linked. No filler.

## Code style

Only write comments that are relevant, informative, and necessary — comment the
non-obvious *why*, never restate what the code already says.

## Example

> **User:** "let's do ABC-204"

1. Fetch ABC-204 from Linear → *"Add rate limiting to the public API."* Summarize
   the scope back and confirm.
2. Branch `feat/ABC-204-public-api-rate-limit` off `dev`.
3. Commit `feat(api): add token-bucket rate limiter (ABC-204)`.
4. PR into `dev` — title `feat: add public API rate limiting (ABC-204)`, body
   summarizes the change and references ABC-204.

> **User:** "let's fix the flaky checkout test"  *(no ticket named)*

1. Ask: "Is this in Linear?" → user says no.
2. Offer to create a ticket; on approval, create it with a clear title + concise
   description, then proceed from step 2 of the example above.

## Related

This is the author side of the workflow. For the release side — turning a
Release Candidate's commits into user-facing release notes — use the
`release-notes` skill. (Note the inverse rule: release notes *strip* ticket keys,
since the audience is end users.)
