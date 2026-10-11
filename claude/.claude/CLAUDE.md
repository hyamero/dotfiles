# Git

Conventional Commits name both branches and commits: `<type>` is `feat`, `fix`,
`chore`, `docs`, `refactor`, etc. A repo's own `AGENTS.md`/`CLAUDE.md` workflow
overrides this section.

- **Branch:** on the base branch (`dev` if it exists, else `main`), create
  `<type>/<name>` off it before the first commit. On any other branch, commit
  there.
- **Commit:** `type(scope): subject` — imperative, scope optional, subject line
  only. After each commit, report its subject and branch.
- **Push:** only after I answer yes to "push to `<branch>`?".
- **Integrate:** into `dev`/`main` via PR; the description says what changed
  and why.

# Code comments

Comment only the non-obvious *why*, concisely.

# Herdr

When `$HERDR_ENV` is `1`, you run inside herdr, my terminal workspace manager
for agents, and herdr owns your terminal work:

- **Read `~/.claude/herdr.md` before your first `herdr` command** of a session.
  It holds the command lookup, layout rules, and verified traps.
- **Long-running processes** (dev servers, watchers, builds, tails) run in herdr
  panes I can see, not background shells.
- **Worktrees** are created with `herdr worktree`, not `git worktree add` or
  `EnterWorktree`, so herdr tracks them.
- **Sibling agents** (full Claude sessions in a worktree) need my OK first: each
  spends real tokens.
- **Notify me** when a task that ran for minutes finishes, or when you're
  blocked on my input:
  `herdr notification show "<title>" --body "<one line>" --sound done` (use
  `--sound request` when you need an answer).
