# dotfiles

Version-controlled configs with a one-command bootstrap for a fresh machine,
kept in a private repo and managed with [GNU Stow](https://www.gnu.org/software/stow/).

Runs on **macOS** and on **Linux/WSL**. Everything platform-specific is behind a
runtime check rather than a separate branch: `.zprofile`/`.zshrc` probe for the
Homebrew prefix, `install.sh` layers `Brewfile.macos` (casks) only on Darwin, and
absolute `$HOME` paths are never committed. See
[Cross-platform notes](#cross-platform-notes).

<img width="1470" height="828" alt="Terminal setup screenshot" src="https://github.com/user-attachments/assets/216243d1-fdcc-4cd8-b326-4ca4f1294876" />

Ghostty shader demo:

https://github.com/user-attachments/assets/15de2272-edf4-4102-8ff2-0d1b4224f1e7

## How it works

Stow uses a symlink-farm layout: each top-level dir is a *package* that mirrors
`$HOME`, and `stow <package>` symlinks its contents into place. So `~/.zshrc`
becomes a symlink to `zsh/.zshrc` in this repo — edit either path, it's the same
file.

Where a target dir already exists and holds other apps' data (`~/.config`,
`~/.claude`), stow only symlinks the individual tracked *leaves* inside it (e.g.
`~/.claude/settings.json`), leaving everything else — caches, sessions, history
— untouched and untracked.

> **Note:** the repo does not live directly under `$HOME` (`~/documents/projects/personal/dotfiles`
> on the Mac, `~/projects/personal/dotfiles` on the WSL box), so every `stow`
> command must pass `-t "$HOME"`. `install.sh` and the snippets below already do.

## Layout

```
dotfiles/
├── AGENTS.md             # repo gotchas + workflow (for coding agents)
├── Brewfile              # generated via `brew bundle dump`; formulae only
├── Brewfile.macos        # casks + Mac-only formulae, layered on by install.sh on Darwin
├── claude-plugins.list   # generated; plugins install.sh reinstalls
├── install.sh            # bootstrap: homebrew → brew bundle → stow → glue → plugins
├── zsh/                  # .zshrc, .zprofile
├── git/                  # .gitconfig, .config/git/ignore
├── claude/
│   └── .claude/
│       ├── settings.json
│       └── CLAUDE.md     # global Claude Code defaults
├── agents/
│   └── .agents/
│       ├── .skill-lock.json
│       └── skills/       # the real skill content
├── herdr/                # .config/herdr/config.toml, macOS (§ prefix)
├── herdr-linux/          # same file, Linux/WSL (` prefix) — one of the two is stowed
└── ghostty/
    └── .config/ghostty/
        ├── config
        └── shaders/      # custom-shader GLSL passes
```

## Setup

### Fresh machine

```sh
git clone git@github.com:hyamero/dotfiles.git ~/documents/projects/personal/dotfiles
cd ~/documents/projects/personal/dotfiles
./install.sh
```

On Linux/WSL, clone wherever you keep projects (`~/projects/personal/dotfiles`) —
nothing depends on the repo's location except that it isn't `$HOME` itself.

`install.sh` is idempotent — safe to re-run anytime. It:

1. Installs **Homebrew** if missing.
2. Runs `brew bundle` on the `Brewfile` (including `stow`), plus `Brewfile.macos`
   when `uname -s` is `Darwin`.
3. Backs up any conflicting real file at a target path to `*.pre-stow`, then
   **stows** every package (with `-t "$HOME"`).
4. Creates the `~/.claude/skills` glue links on first run (see
   [What's tracked vs. not](#whats-tracked-vs-not)).
5. Reinstalls the Claude plugins listed in `claude-plugins.list` — if the
   `claude` CLI is present. Re-run after installing Claude Code if it wasn't.

### Verify

- `ls -la ~/.zshrc ~/.gitconfig ~/.claude/settings.json` — symlinks pointing into the repo
- A new `zsh` shell loads without errors; `git config --global user.name` resolves
- `claude` sees its settings + skills (paths resolve through the symlinks)

## Daily use

`~/.zshrc` etc. are symlinks into this repo — edit them as usual, then commit
from the repo root. Review before staging: tools and installers also write into
these files (herdr's duplicate hook, the bun installer's `.zshrc` block,
machine-specific Claude settings), and `git add -A` would sweep that in.

```sh
git status && git diff
git add <paths> && git commit -m "..." && git push
```

### Add a config

Place the file in a package dir mirroring its `$HOME` path, then re-stow from
the repo root:

```sh
stow -t "$HOME" --restow <package>
```

### Refresh the Brewfile

```sh
brew bundle dump --file=Brewfile --force --no-vscode
```

`--no-vscode` keeps VS Code extensions out; they sync via Settings Sync.

> **Run this on the Mac only, and move any `cask` lines — and Mac-only formulae
> like `tailscale` and `nosleep` — into `Brewfile.macos` afterwards.** `dump`
> writes one flat file; a `cask` left in `Brewfile` aborts the entire bundle run
> on Linux. Dumping on Linux would also drop every Mac-only formula from the list.

### Refresh the plugin list

After adding or removing Claude plugins, regenerate `claude-plugins.list` from
the installed set:

```sh
{ echo "# Claude plugins to reinstall on a fresh machine."
  echo "# Generated from ~/.claude/plugins/installed_plugins.json — see README (Refresh the plugin list)."
  python3 -c 'import json; print("\n".join(sorted(json.load(open(__import__("os").path.expanduser("~/.claude/plugins/installed_plugins.json")))["plugins"])))'
} > claude-plugins.list
```

## What's tracked vs. not

**The skills glue.** `~/.claude/skills` is *not* tracked — it's a directory of
relative symlinks (`../../.agents/skills/<name>`) created by a skills CLI that
only resolve from `$HOME`. The real skill content lives in `~/.agents/skills`
and is tracked via the `agents` package; `install.sh` regenerates the glue links
on a fresh machine.

**Plugins.** Only `claude-plugins.list` is tracked, not plugin code. It's the
restore source because `settings.json`'s `enabledPlugins` is auto-managed and
pruned by Claude Code, so it can't be relied on.

**Herdr.** Only `config.toml` is tracked. herdr writes its Claude hook
(`~/.claude/hooks/herdr-agent-state.sh`) itself via `herdr integration install
claude`; `settings.json` references it behind an existence guard, so it's a
no-op on a machine without herdr. That install command also appends a second,
absolute-path `SessionStart` hook to `settings.json` — revert it with
`git checkout -- claude/.claude/settings.json`.

**Deliberately excluded:**

- `~/.config/gh` — contains auth tokens
- `~/.config/raycast`, `~/.config/opencode` — machine state
- `~/.config/fish` — unused
- `~/.claude` machine state — cache, sessions, history, plugins, projects
- `~/.config/herdr` runtime state — `session.json`, `*.log`, `*.sock`
- `~/.local/state/herdr/` — agent-detection state, regenerated by herdr
- `~/.claude/hooks/herdr-agent-state.sh` — herdr-managed, overwritten on update

**Secrets.** No credentials are committed, even though the repo is private. Keep
machine-specific secrets in an untracked `~/.zshrc.local`; the last line of
`.zshrc` sources it when present.

**Machine-local git config.** `~/.gitconfig.local` is included from the tracked
`.gitconfig` and is where per-machine settings go — credential helpers (the one
`gh auth setup-git` writes points at an absolute `gh` path, which differs per
platform), per-machine identities, or `commit.gpgsign = false` on a box whose
signing key isn't loaded. git skips the include silently when the file is absent.

## Cross-platform notes

The repo is shared between a Mac and a WSL (Ubuntu) box. What differs, and how
it's handled:

| Difference | Handling |
| --- | --- |
| Homebrew prefix (`/opt/homebrew` vs. `/home/linuxbrew/.linuxbrew`) | `.zprofile` probes both; `.zshrc` repeats the probe for non-login shells, which never source `.zprofile`. `install.sh` sources `shellenv` from whichever prefix the installer created. |
| Casks | Linux brew has none — they live in `Brewfile.macos`, applied only on Darwin. |
| `$HOME` (`/Users/…` vs. `/home/…`) | Nothing tracked may hardcode it. `settings.json` hook commands use `$HOME`; `.gitconfig` uses `~`. |
| Untracked machine-local files (`statusline.sh`, herdr's `herdr-agent-state.sh`, `.orca` hooks) | Every `settings.json` hook that references one is guarded with a `[ -f … ] && … \|\| true` so a missing file is a no-op, not a failing hook. |
| Standalone pnpm location (`$PNPM_HOME` vs. `$PNPM_HOME/bin`) | Both are on PATH; `$PNPM_HOME/bin` is *appended* so corepack's shim still wins. |
| Untrusted taps | Linux brew refuses third-party taps until trusted. Entries `brew bundle dump` marks `trusted: true` handle this themselves; the rest need `brew trust tursodatabase/tap && brew trust libsql/sqld && brew trust blankeos/tap` first. |
| herdr prefix key (`§` vs. `` ` ``) | Separate `herdr` / `herdr-linux` stow packages, selected by `uname -s`. herdr's config has no include support and `prefix` takes one string, so the file is duplicated; `install.sh` warns if the two drift apart in anything but the prefix line. A change to one belongs in both. |
| Ghostty | Only used on the Mac; on WSL the terminal is Windows Terminal, and the `macos-*` keys in `ghostty/config` are inert. The package is still stowed — harmless. |
