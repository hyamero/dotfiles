# Codex instructions

## Terminal workflow

- I use Ghostty with Herdr to manage terminal panes, Git worktrees, and coding agents.
- When I ask you to inspect or coordinate work in Herdr, load the Herdr skill, verify `HERDR_ENV=1`, and check the installed CLI help for the relevant command group.
- When I ask what another agent is working on, use Herdr to identify its pane, confirm its worktree and branch, and read its status or recent output. Keep the inspection read-only and preserve my focus.
- Before editing in a shared worktree, check its branch and working tree status. If another agent is working on the same files, surface the overlap before editing. Start agents and send prompts only when I ask.
- When running inside Herdr, run long-lived commands such as dev servers, watchers, builds, and log tails in one labeled Herdr tab per session. Create the tab without shifting my focus, reuse it, and label its panes by what they run. Check whether another agent is already running the same job first.
- When I ask for a worktree and you are running inside Herdr, create it through `herdr worktree` so it is tracked in Herdr. Follow the repository's rules for the base branch.
- When a task that took several minutes finishes inside Herdr, send a single completion notification with `herdr notification show "<title>" --body "<one-line summary>" --sound done`.

## Git workflow

- Follow the repository's Git workflow. Use imperative Conventional Commit subjects and report the commit subject and branch after each commit.
- Get my approval before pushing to a branch. Approval to push also covers opening its PR. If I have not approved a push, get my approval before opening the PR.
- In Referenta, create a new feature branch only when I explicitly ask for one in the current conversation. Otherwise, use the checked-out branch, subject to the repository's rules.

## Code comments

- Keep comments concise and use them to explain non-obvious reasons behind the code.
