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

**Herdr is the default for terminal layout, processes, worktrees, and sibling
agents.** Load the herdr skill before the first herdr command of a session —
its "only when the user mentions Herdr" trigger is overridden here. Where the
skill and this file disagree, this file wins. To look up a command:

- `herdr <group>` with no subcommand prints that group's usage (`tab`, `pane`,
  `worktree`, `workspace`, `agent`, `notification`). `--help` on a subcommand
  does NOT work — it prints the top-level help.
- `herdr api schema --json` has every method's exact params.
- Never run bare `herdr` (attaches the TUI) or probe a mutating command by
  leaving out arguments — `create` commands run with defaults.

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

## Long-running processes go in panes, in one labeled tab

Dev servers, watchers, builds, tails, and sibling agents belong in a pane I can
see — but never split my current tab. Every pane you open this session goes in
**one tab of your own**, however many panes it needs. (Overrides the herdr
skill's same-tab default.)

1. **First pane only:** create the tab, unfocused, labeled `<repo>: <purpose>`:
   `herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd <path> --label "dotfiles: dev" --no-focus`
   → `.result.tab.tab_id` and `.result.root_pane.pane_id`. Use the root pane
   first. Reuse this tab for the rest of the session; if `herdr tab list` shows
   it's gone, create a new one.
2. **More panes:** split a pane *inside that tab* —
   `herdr pane split <tab_pane_id> --direction right --cwd <path> --no-focus`
   → `.result.pane.pane_id`. Wide → `right`, narrow → `down`.
3. **Label every pane** with what runs in it, short:
   `herdr pane rename <pane_id> "next dev :3000"`. If the tab's purpose
   changes, `herdr tab rename <tab_id> "<repo>: <purpose>"`.
4. `herdr pane run <pane_id> '<command>'`
5. `herdr pane wait-output <pane_id> --match "<token>" --timeout 30000`
6. `herdr pane read <pane_id> --source visible --lines 40` to inspect.
7. **Cleanup:** `herdr pane close <pane_id>` for panes you're done with;
   `herdr tab close <tab_id>` once the work is finished — it kills every
   process in the tab. Don't leave strays behind.

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

## Worktrees go through herdr

Create worktrees with `herdr worktree`, never `git worktree add`, the
`EnterWorktree` tool, or a skill's git fallback — herdr then tracks the checkout
and gives it a visible workspace. (create / rename / list / remove verified;
`--base` and `open` are from `herdr worktree` usage only.)

- `herdr worktree create --cwd <repo> --branch <type>/<name> --label "<repo>: <name>" --no-focus`
  (`--base <ref>` to branch from something other than `HEAD`). It creates a
  **new workspace** labeled `--label`, checked out at
  `~/.herdr/worktrees/<repo>/<branch-slug>`, with one tab and a shell pane at
  that path → `.result.workspace.workspace_id`, `.result.tab.tab_id`,
  `.result.root_pane.pane_id`.
- That tab comes labeled `1` — rename it: `herdr tab rename <tab_id> "<purpose>"`,
  and label its panes as above. Panes for work in the worktree go in *its*
  workspace, not your session tab.
- `herdr worktree list --cwd <repo>` shows checkouts and their workspaces;
  `herdr worktree open --cwd <repo> --branch <name>` reopens one.
- `herdr worktree remove --workspace <workspace_id>` deletes the checkout and
  closes its workspace but **keeps the branch** — delete that with git only once
  it's merged or I say so. Add `--force` only with my OK (discards changes).
- Never pass `--trust-repository` on your own; it's for repos I've verified.

## Parallel agents

For genuinely independent work too big for a subagent — a real sibling Claude
session in its own herdr worktree: create it as above, then
`herdr agent start <name> --kind claude --pane <root_pane_id> --timeout 60000`
in the worktree's root pane.

- **Ask me before spawning one.** Each is a full Claude session spending real
  tokens; that's my call, not yours.
- **All agent targets are `pane_id`s** (`w3:p1`) — never the agent session UUID
  from `agent list`, which `agent read` rejects as `agent_not_found`.
- Branches follow the same `<type>/<name>` convention as the git workflow above.
