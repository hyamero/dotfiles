# Git workflow

- **Ask once per session.** The first time I ask you to commit, push, or open a PR in a session, ask me first: **commit directly to the current branch**, or **branch out from it first**? When the current branch is `dev` or `main`, branching out is the recommended default — but I decide. Apply my answer for the rest of the session unless I say otherwise.
- **Branching out:** create the new branch off the current branch — `feature/<name>` for features, `fix/<name>` for fixes.
- **Already on a non-base branch** (not `dev`/`main`): that *is* the working branch — keep committing there.
- **Base branch:** `dev` if the repo has one, otherwise `main`.
- **Prefer to integrate via a PR** rather than pushing directly to `dev`/`main`. PR descriptions: concise — what changed and why, no filler.

# Commits

- No attribution trailers (no "Generated with Claude Code", no `Co-Authored-By`). Also enforced in `settings.json`.
- Concise messages: a clear subject line; add a body only when the "why" isn't obvious from the subject.

# Code comments

- Only relevant, informational comments, and only when necessary.
- Comment the non-obvious "why" — don't restate what the code already says.
