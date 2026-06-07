# Git workflow

- **First commit/push/PR request of a session → ask:** commit to the current
  branch, or branch out first? (Recommended on `dev`/`main`: branch out.) The
  answer holds for the rest of the session.
- **New branches:** off the current branch, named `<type>/<name>` by
  Conventional Commits type — `feat/`, `fix/`, `chore/`, `docs/`, etc.
- **Already on a non-base branch:** that is the working branch — keep
  committing there. Base branch: `dev` if it exists, else `main`.
- **After every commit:** announce what was committed and to which branch.
- **Never push without my approval.** A commit stops at the commit; before any
  push, ask "push to `<branch>`?" and wait.
- **Integrate via PR**, not direct pushes to `dev`/`main`. PR description:
  what changed and why, no filler.

# Triggers

- "git status" → show: current branch · commits made this session ·
  ahead/behind `origin/<branch>` (pushed vs local-only).

# Commits

- Conventional Commits: `type(scope): subject` — imperative subject, scope
  optional.
- Subject line only, no body. No `Co-Authored-By` trailer (also enforced in
  `settings.json`).

# Code comments

- Technical and necessary only — concise.
- Comment the non-obvious "why"; never restate what the code says.
