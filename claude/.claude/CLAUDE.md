# Git workflow

- **On a base branch** (`dev` if it exists, else `main`): branch out before the
  first commit — off the current branch, named `<type>/<name>` by Conventional
  Commits type (`feat/`, `fix/`, `chore/`, `docs/`, etc.). Don't ask.
- **On any other branch:** that is the working branch — keep committing there.
- A repo's own instructions (e.g. "commit directly to `main`") override both.
- **After every commit:** announce what was committed and to which branch.
- **Never push without my approval.** A commit stops at the commit; before any
  push, ask "push to `<branch>`?" and wait.
- **Integrate via PR**, not direct pushes to `dev`/`main`. PR description:
  what changed and why, no filler.

# Commits

- Conventional Commits: `type(scope): subject` — imperative subject, scope
  optional.
- Subject line only, no body. No `Co-Authored-By` trailer.

# Code comments

- Technical and necessary only — concise.
- Comment the non-obvious "why"; never restate what the code says.

# Herdr

**Applies only when `$HERDR_ENV` is `1`** — otherwise you're not inside herdr;
skip this section.

You run inside herdr, my terminal workspace manager for AI agents. `herdr` is on
PATH and talks to the running server over a socket. Subcommands emit JSON on
stdout; `pane read` emits plain text. **Every wait is indefinite without
`--timeout`** — always pass one.

## Notify me

- On finishing work I'm probably not watching, or when blocked and needing my
  input: `herdr notification show "<title>" --body "<one line>" --sound done`.
- `--sound request` when you need an answer, `done` when work is complete.
- Skip it for quick foreground replies — I'm already looking.

## Orient before acting

- `herdr pane current` → your own `pane_id` and `workspace_id`.
- `herdr agent list` → every agent's `pane_id`, `cwd`, `terminal_title`, and
  `agent_status` (`idle`/`working`/`blocked`). Check it before assuming a job
  isn't already running in another pane.

## Long-running processes go in panes, not background shells

Dev servers, watchers, builds, and tails belong in a pane I can see:

1. `herdr pane split --current --direction right --ratio 0.4 --cwd <path> --no-focus`
   — a pane on the **right**, not the bottom. Returns JSON containing the new
   `pane_id`.
2. `herdr pane run <pane_id> '<command>'`
3. `herdr pane wait-output <pane_id> --match "<token>" --timeout 30000`
4. `herdr pane read <pane_id> --source visible --lines 40` to inspect.
5. `herdr pane close <pane_id>` when done — don't leave strays behind.

Three traps, each verified the hard way:

- **`pane run` types into the interactive shell, which re-parses the text.**
  Pass the command as ONE already-shell-quoted argument. Separate argv words
  lose their quotes and get glob-expanded:

  ```sh
  herdr pane run w5:p2 'pnpm dev'                          # good
  herdr pane run w5:p2 'node -e '\''console.log(1)'\'''    # good, pre-quoted
  herdr pane run w5:p2 node -e 'console.log(1)'            # BREAKS: quotes lost
  ```

- **`wait-output` searches the echoed command line too.** Match a token that
  appears only in the program's own output (`Local:`, `compiled successfully`),
  never a substring of the command you just ran — that matches instantly.
- **`pane read` defaults to `--source recent`, which is often empty.** Use
  `--source visible`.

## Parallel agents

For genuinely independent work too big for a subagent — a real sibling Claude
session in its own `herdr worktree`. Load the herdr skill for the commands.

- **Ask me before spawning one.** Each is a full Claude session spending real
  tokens; that's my call, not yours.
- **All agent targets are `pane_id`s** (`w3:p1`) — never the agent session UUID
  from `agent list`, which `agent read` rejects as `agent_not_found`.
- Branches follow the same `<type>/<name>` convention as the git workflow above.
