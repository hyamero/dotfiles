# dotfiles

Shell, git, terminal and AI-agent configs for **macOS** and **Linux/WSL**,
managed with [GNU Stow](https://www.gnu.org/software/stow/).

<img width="1470" height="828" alt="Terminal setup screenshot" src="https://github.com/user-attachments/assets/216243d1-fdcc-4cd8-b326-4ca4f1294876" />

Ghostty shader demo:

https://github.com/user-attachments/assets/3ae67c7f-76c7-44b0-ab5b-b2202182e7a5

## What's inside

| Package | Configures |
| --- | --- |
| `zsh` | Oh My Zsh with fzf, z, autosuggestions and syntax highlighting |
| `git` | SSH commit signing |
| `ghostty` | GitHub Dark Colorblind, VictorMono Nerd Font, a galaxy backdrop shader and a smearing caret |
| `herdr` | [herdr](https://herdr.dev) workspace config (`herdr-linux` swaps the prefix key) |
| `claude` | Claude Code settings and global instructions |
| `agents` | A few general agent skills |

## Install

```sh
git clone https://github.com/hyamero/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

The script installs Homebrew and the `Brewfile` packages, backs up conflicting
files as `*.pre-stow`, and stows every package into `$HOME`. Oh My Zsh, its
plugins and the font are installed separately.

To add a file later, put it in a package at its `$HOME`-relative path and run
`stow -t "$HOME" --restow <package>`.

## Making it your own

- Change `[user]` in `git/.gitconfig`.
- Trim `Brewfile` and `claude-plugins.list` to what you use.
- Keep secrets and per-machine settings in `~/.zshrc.local` and
  `~/.gitconfig.local`; both are sourced when present and never tracked.
