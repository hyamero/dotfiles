# dotfiles

GNU Stow–managed dotfiles, shared between a **Mac** and a **WSL (Ubuntu)** box.
Each top-level dir (`zsh/`, `git/`, `claude/`, `agents/`, `herdr/`, `ghostty/`)
is a stow *package* mirroring `$HOME`; stow symlinks its contents into place.
See README.md for usage and the Cross-platform notes table.

## Critical gotchas

- **Never commit an absolute `$HOME` path.** Two machines, two homes
  (`/Users/hyamero` vs. `/home/hyamero`). Use `$HOME` in `settings.json` hook
  commands, `~` in `.gitconfig`, `$HOME` in shell files. A hardcoded
  `/Users/hyamero/...` silently breaks only on the other box — grep for it
  before committing.
- **Homebrew's prefix differs per platform** (`/opt/homebrew` vs.
  `/home/linuxbrew/.linuxbrew`). `.zprofile`, `.zshrc` and `install.sh` each
  probe for both; don't collapse them back to one path. `.zshrc` needs its own
  probe because non-login shells never source `.zprofile`.
- **Casks belong in `Brewfile.macos`, not `Brewfile`.** Linux brew has no cask
  support and one `cask` line aborts the *entire* `brew bundle` run. Note that
  `brew bundle dump` writes a single flat file — run it on the Mac and move the
  cask lines back out afterwards. `Brewfile.macos` also holds Mac-only
  *formulae* (`tailscale`), which a dump likewise flattens into `Brewfile`;
  move those back too, or WSL installs a Tailscale daemon it never uses.
  Linux also refuses untrusted third-party taps until `brew trust <tap>` is run.
- **`settings.json` hooks must tolerate a missing target.** `statusline.sh`,
  herdr's `herdr-agent-state.sh` and the `.orca` hooks are all untracked,
  machine-local files. Every hook referencing one is wrapped in
  `[ -f … ] && … || true`; drop the guard and every session on the other machine
  fires a failing hook.
- **Per-machine git settings go in `~/.gitconfig.local`**, included from the
  tracked `.gitconfig`. Credential helpers in particular embed an absolute `gh`
  path, so they must never land in the tracked file.
- **Repo is NOT under `$HOME`** (`~/documents/projects/personal/dotfiles` on the
  Mac, `~/projects/personal/dotfiles` on WSL).
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
- **`herdr integration install claude` appends a duplicate hook.** It writes
  `~/.claude/hooks/herdr-agent-state.sh` (untracked, herdr-managed — that part is
  fine) and then "ensures" a `SessionStart` hook in `settings.json` with a
  *hardcoded absolute path*. It does not recognise the guarded hook already
  tracked there, so you end up with two. `settings.json` is a symlink into this
  repo, so that lands as a repo diff: `git checkout -- claude/.claude/settings.json`
  after running it. Same trap for any installer offering to edit a shell profile
  (the bun installer appends a duplicate `BUN_INSTALL` block to `.zshrc`) —
  check `git status` in this repo after running one.
- **herdr's prefix key is platform-split across two stow packages.** `herdr`
  (macOS, `§`) and `herdr-linux` (`` ` ``) both provide
  `.config/herdr/config.toml`, so exactly one is stowed — `install.sh` picks by
  `uname -s`. herdr's config has no include or conditional support and `prefix`
  rejects an array, hence the duplication. **Any other change must be made in
  both files**; install.sh warns when they drift apart in anything but the
  prefix line. Note a TOML parse error silently drops herdr to *all* defaults
  rather than failing loudly — run `herdr config check` after editing, and
  `herdr server reload-config` to apply without restarting the session.
- **Herdr rewrites its own `config.toml`** (theme picker, onboarding flag), so a
  write that replaces the file rather than editing in place would drop the stow
  symlink. After changing herdr settings in the TUI, `ls -la
  ~/.config/herdr/config.toml` should still be a symlink; if it's a real file,
  move it back into `herdr/.config/herdr/` and `stow -t "$HOME" --restow herdr`.
  Only `config.toml` is tracked — logs, sockets, and `session.json` stay local.
- **Ghostty config lives at `.config/ghostty`, not Application Support.** macOS
  Ghostty reads `~/Library/Application Support/com.mitchellh.ghostty/config`
  too, and a file there wins over the XDG path — so that copy is parked as
  `config.pre-stow`. If shader changes stop taking effect, check nothing has
  recreated a real `config` there (`ghostty +show-config | grep custom-shader`
  prints the paths actually in use). `custom-shader` values are relative to the
  config file, so `shaders/*.glsl` resolves through the stow symlink into the
  repo. Reload in-place with `⌘R`; `ghostty +validate-config` checks syntax but
  does NOT compile the GLSL — a broken shader fails silently at load.
- **Claude plugins:** `claude-plugins.list` (generated from
  `~/.claude/plugins/installed_plugins.json`) is the tracked restore list;
  install.sh reinstalls from it. Do NOT read `settings.json`'s `enabledPlugins`
  — Claude Code auto-manages and prunes it, so it's unreliable. The
  `claude-plugins-official` marketplace is built-in.

## Workflow (this repo only)

- Commit and push **directly to `main`** — solo project, no branch/PR. Overrides
  the global ask-and-PR rule in `~/.claude/CLAUDE.md`.
- Deleting **remote** branches needs explicit approval (auto-mode blocks it).

## Commands

- Refresh Brewfile: `brew bundle dump --file=Brewfile --force --no-vscode`
  (VS Code extensions excluded — synced via Settings Sync).
- Re-link a package after adding files: `stow -t "$HOME" --restow <package>`.
- Design specs are in `docs/superpowers/` (gitignored, local only).
