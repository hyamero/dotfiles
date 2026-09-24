# dotfiles

Shell, git, terminal and AI-agent configs for **macOS** and **Linux/WSL**,
managed with [GNU Stow](https://www.gnu.org/software/stow/) and bootstrapped by
one script.

<img width="1470" height="828" alt="Terminal setup screenshot" src="https://github.com/user-attachments/assets/216243d1-fdcc-4cd8-b326-4ca4f1294876" />

Ghostty shader demo:

https://github.com/user-attachments/assets/15de2272-edf4-4102-8ff2-0d1b4224f1e7

## What's inside

| Package | What it configures |
| --- | --- |
| `zsh` | Oh My Zsh with `fzf`, `z`, autosuggestions and syntax highlighting; Homebrew and pnpm path setup for both platforms |
| `git` | SSH commit signing, with per-machine overrides in an untracked `~/.gitconfig.local` |
| `ghostty` | GitHub Dark Colorblind theme, VictorMono Nerd Font, and two custom GLSL shaders: an animated galaxy backdrop and a caret that smears between cells |
| `herdr` / `herdr-linux` | [herdr](https://herdr.dev) terminal workspace config; only the prefix key differs per platform |
| `claude` | Claude Code settings and global instructions |
| `agents` | A collection of agent skills (`~/.agents/skills`) for frontend, design, testing and workflow tasks |

Packages are listed in `Brewfile` (cross-platform) and `Brewfile.macos` (casks
and Mac-only formulae).

## Install

```sh
git clone https://github.com/hyamero/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The repo can live anywhere except `$HOME` itself. `install.sh` is idempotent and:

1. Installs Homebrew if it's missing.
2. Runs `brew bundle` on `Brewfile`, plus `Brewfile.macos` on macOS.
3. Moves any conflicting file to `*.pre-stow`, then stows every package into `$HOME`.
4. Links the agent skills into `~/.claude/skills`.
5. Reinstalls the Claude Code plugins in `claude-plugins.list`, if the `claude` CLI is installed.

Not handled by the script: [Oh My Zsh](https://ohmyz.sh) and its
`zsh-autosuggestions` / `zsh-syntax-highlighting` plugins, and the VictorMono
Nerd Font.

### Making it your own

If you fork this, change at least:

- `[user]` in `git/.gitconfig`: name, email and signing key.
- The herdr `prefix` key in both herdr configs.
- `Brewfile` and `claude-plugins.list`, down to the tools you actually use.

Keep secrets and machine-specific settings in `~/.zshrc.local` and
`~/.gitconfig.local`. Both are sourced when present and never tracked.

## How it works

Each top-level directory is a Stow *package* that mirrors `$HOME`, so
`zsh/.zshrc` is symlinked to `~/.zshrc`. Editing either path edits the same file.

When a target directory already holds other data (`~/.config`, `~/.claude`),
Stow links only the tracked files inside it and leaves caches, sessions and
history alone.

To add a config, put the file in a package at its `$HOME`-relative path and
re-stow:

```sh
stow -t "$HOME" --restow <package>
```

Always pass `-t "$HOME"`: Stow otherwise targets the repo's parent directory.

## Cross-platform notes

Everything platform-specific is handled by a runtime check, not a separate
branch.

| Difference | Handling |
| --- | --- |
| Homebrew prefix (`/opt/homebrew` vs. `/home/linuxbrew/.linuxbrew`) | `.zprofile`, `.zshrc` and `install.sh` each probe for both. `.zshrc` needs its own probe because non-login shells never read `.zprofile`. |
| Casks | Linux Homebrew has none, so they live in `Brewfile.macos`, applied only on macOS. |
| Home directory | No absolute home path is committed. `settings.json` hooks use `$HOME`; `.gitconfig` uses `~`. |
| Optional local files | Claude Code hooks that point at untracked scripts (status line, herdr state) are wrapped in `[ -f … ] && … \|\| true`, so a missing script is a no-op. |
| Third-party taps | Linux Homebrew refuses untrusted taps. Entries marked `trusted: true` handle this; for the rest, run `brew trust tursodatabase/tap && brew trust libsql/sqld && brew trust blankeos/tap` first. |
| herdr prefix key | herdr's config has no includes and `prefix` takes one value, so there are two packages and `install.sh` stows the one for the current OS. It warns if they drift apart in anything but the prefix line. |
| Ghostty | macOS only. On Linux the package is stowed but unused. |

## Maintenance

**Refresh the Brewfile** (on macOS):

```sh
brew bundle dump --file=Brewfile --force --no-vscode
```

`dump` writes one flat file, so move cask lines and Mac-only formulae back into
`Brewfile.macos` afterwards. A single `cask` line in `Brewfile` aborts the whole
run on Linux.

**Refresh the plugin list** after installing or removing Claude Code plugins:

```sh
{ echo "# Claude plugins to reinstall on a fresh machine."
  echo "# Generated from ~/.claude/plugins/installed_plugins.json — see README (Refresh the plugin list)."
  python3 -c 'import json; print("\n".join(sorted(json.load(open(__import__("os").path.expanduser("~/.claude/plugins/installed_plugins.json")))["plugins"])))'
} > claude-plugins.list
```

`settings.json`'s `enabledPlugins` isn't used as the restore list because
Claude Code rewrites and prunes it.

**Watch for installer edits.** `settings.json` and `.zshrc` are symlinks into
the repo, so tools that edit them show up in `git diff`. For example, `herdr
integration install claude` adds a duplicate hook. Review `git diff` before
committing.

## Not tracked

- `~/.config/gh` (auth tokens) and any other credentials
- App and agent state: Claude Code caches, sessions and plugin code; herdr
  sessions, logs and sockets
- `~/.claude/skills`, which `install.sh` regenerates as links into `~/.agents/skills`
- `~/.zshrc.local` and `~/.gitconfig.local`
