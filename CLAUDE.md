# dotfiles

GNU Stow–managed macOS dotfiles. Each top-level dir (`zsh/`, `git/`, `claude/`,
`agents/`) is a stow *package* mirroring `$HOME`; stow symlinks its contents
into place. See README.md for usage.

## Critical gotchas

- **Repo is NOT under `$HOME`** (it's in `~/Documents/Projects/personal/dotfiles`).
  Every `stow` command MUST pass `-t "$HOME"`, e.g. `stow -t "$HOME" --restow claude`.
  Without it, stow targets the repo's parent dir.
- **`~/.claude/skills` is untracked glue — never track it.** It's a real dir of
  *relative* symlinks (`../../.agents/skills/<name>`) that only resolve from
  `$HOME`. The real skill content lives in `~/.agents/skills`, tracked via the
  `agents` package. install.sh recreates the glue links on first run.
- **install.sh `backup_conflicts` needs the `-ef` guard.** Files inside a folded
  directory symlink (e.g. `~/.agents/skills`) are real files reached *through*
  the link; a naive `[ -e ] && [ ! -L ]` backup renames repo files. The
  `! [ "$target" -ef <repo file> ]` check skips already-stowed paths.
- **Claude plugins:** only the `enabledPlugins` list in `settings.json` is
  tracked, not the plugin code. install.sh reinstalls them
  (`claude plugin install <name>@claude-plugins-official`); the marketplace is
  built-in.

## Workflow (this repo only)

- Commit and push **directly to `main`** — solo project, no branch/PR. Overrides
  the global ask-and-PR rule in `~/.claude/CLAUDE.md`.
- Deleting **remote** branches needs explicit approval (auto-mode blocks it).

## Commands

- Refresh Brewfile: `brew bundle dump --file=Brewfile --force --no-vscode`
  (VS Code extensions excluded — synced via Settings Sync).
- Re-link a package after adding files: `stow -t "$HOME" --restow <package>`.
- Design specs are in `docs/superpowers/` (gitignored, local only).
