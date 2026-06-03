# Git workflow

- **Never commit or push directly to `dev` or `main`** — they are protected base branches.
- **Base branch:** `dev` if the repo has one, otherwise `main`.
- **Starting work:**
  - On the base branch (`dev`/`main`) → create a new branch off it: `feature/<name>` for features, `fix/<name>` for fixes.
  - Already on a non-base branch (anything that isn't `dev`/`main`) → that *is* the working branch; keep committing there, don't branch again.
- **Integrating:** push the working branch and open a PR into the base branch. A PR is the only path into `dev`/`main`.
- **PR descriptions:** concise — what changed and why, no filler.

# Commits

- No attribution trailers (no "Generated with Claude Code", no `Co-Authored-By`). Also enforced in `settings.json`.
- Concise messages: a clear subject line; add a body only when the "why" isn't obvious from the subject.

# Code comments

- Only relevant, informational comments, and only when necessary.
- Comment the non-obvious "why" — don't restate what the code already says.
