# Herdr operations

Reached from `~/.claude/CLAUDE.md`. Where the herdr skill disagrees with this
file, this file wins.

## Before acting

1. `herdr pane current` → your `pane_id`, `tab_id`, `workspace_id`.
2. `herdr agent list` → check whether the job already runs in another pane.

## Command lookup

- `herdr <group>` with no subcommand prints that group's usage (`tab`, `pane`,
  `worktree`, `workspace`, `agent`, `notification`). `--help` after a
  subcommand prints only the top-level help.
- `herdr api schema --json` → exact params for every method.
- For anything this file doesn't cover, load the herdr skill — its "only when
  the user mentions Herdr" trigger doesn't apply here.
- Commands emit JSON (`pane read` emits text). Take IDs from `.result`.
- Every wait takes `--timeout <ms>`; without it the wait is indefinite.
- Explore with the lookups above only: bare `herdr` attaches the TUI, and a
  `create` with arguments left out runs with defaults.

## Processes: one labeled tab per session

Every pane you open goes in one tab of your own, created unfocused, however many
panes it needs. My current tab stays as it is.

1. **First pane:** `herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd <path> --label "<repo>: <purpose>" --no-focus`
   → `.result.tab.tab_id`, `.result.root_pane.pane_id`. Use the root pane first.
   Reuse the tab all session; if `herdr tab list` no longer shows it, create
   another.
2. **More panes:** `herdr pane split <pane_in_your_tab> --direction right --cwd <path> --no-focus`
   → `.result.pane.pane_id`. Wide pane → `right`, narrow → `down`.
3. **Label** each pane with what runs in it (`herdr pane rename <pane_id> "next dev :3000"`);
   keep the tab label current (`herdr tab rename <tab_id> "<repo>: <purpose>"`).
4. `herdr pane run <pane_id> '<command>'`
5. `herdr pane wait-output <pane_id> --match "<token>" --timeout 30000`
6. `herdr pane read <pane_id> --source visible --lines 40`
7. **Clean up** when the work is finished: `herdr pane close <pane_id>` per
   pane, or `herdr tab close <tab_id>`, which kills every process in the tab.

Verified traps:

- **`pane run` re-parses its text in the shell.** Pass ONE pre-quoted argument;
  separate argv words lose their quotes and get glob-expanded.
  ```sh
  herdr pane run w5:p2 'pnpm dev'                          # good
  herdr pane run w5:p2 'node -e '\''console.log(1)'\'''    # good, pre-quoted
  herdr pane run w5:p2 node -e 'console.log(1)'            # breaks
  ```
- **`wait-output` also matches the echoed command line.** Match a token only the
  program prints (`Local:`, `compiled successfully`).
- **`pane read` defaults to `--source recent`**, often empty: pass
  `--source visible`.

## Worktrees

Create, rename, list, and remove are verified; `--base` and `open` come from
`herdr worktree` usage.

- `herdr worktree create --cwd <repo> --branch <type>/<name> --label "<repo>: <name>" --no-focus`
  (`--base <ref>` to start from something other than `HEAD`) creates a **new
  workspace** at `~/.herdr/worktrees/<repo>/<branch-slug>` with one tab and a
  shell pane → `.result.workspace.workspace_id`, `.result.tab.tab_id`,
  `.result.root_pane.pane_id`.
- Its tab arrives labeled `1`: rename it and label its panes as above. Work for
  the worktree stays in its workspace.
- `herdr worktree list --cwd <repo>` shows checkouts and their workspaces;
  `herdr worktree open --cwd <repo> --branch <name>` reopens one.
- `herdr worktree remove --workspace <workspace_id>` deletes the checkout and
  closes the workspace; the branch survives. Delete the branch with git once
  it's merged or I say so.
- `--force` (discards changes) and `--trust-repository` need my OK.

## Sibling agents

After I approve: create a worktree as above, then
`herdr agent start <name> --kind claude --pane <root_pane_id> --timeout 60000`
in its root pane.

- Target agents by `pane_id` (`w3:p1`) or live name; `agent read` rejects the
  session UUID from `agent list` as `agent_not_found`.
- `herdr agent prompt <pane_id> "<task>" --wait --until idle --timeout <ms>`,
  then `herdr agent read <pane_id> --lines 60` for the result.
