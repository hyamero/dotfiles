# Git workflow

- **Ask once per session.** The first time I ask you to commit, push, or open a PR in a session, ask me first: **commit directly to the current branch**, or **branch out from it first**? When the current branch is `dev` or `main`, branching out is the recommended default — but I decide. Apply my answer for the rest of the session unless I say otherwise.
- **Branching out:** create the new branch off the current branch, named with the Conventional Commits type that matches the work — `feat/<name>`, `fix/<name>`, `chore/<name>`, `docs/<name>`, etc.
- **Already on a non-base branch** (not `dev`/`main`): that *is* the working branch — keep committing there.
- **Base branch:** `dev` if the repo has one, otherwise `main`.
- **Prefer to integrate via a PR** rather than pushing directly to `dev`/`main`. PR descriptions: concise — what changed and why, no filler.
- **Never push without my permission.** A commit stops at the commit — before any push, ask "push to `<branch-name>`?" and wait for my approval.
- **Announce every commit:** after committing, state what was committed and to which branch.
- **When I say "git status", show:** (1) the current branch name, (2) commits made during this session, (3) where the branch stands vs its remote (`origin/<branch>` — ahead/behind, i.e. what's pushed vs local-only).

# Commits

- **Conventional Commits** format: `type(scope): subject`, where `type` is `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, etc. Imperative subject; `scope` optional.
- No `Co-Authored-By` trailer. Also enforced in `settings.json`.
- Subject line only — no commit body/description.

# Code comments

- Technical, informational comments only — relevant, necessary, and concise.
- Comment the non-obvious "why" — don't restate what the code already says.
