# dotfiles

Personal macOS configs, managed with [GNU Stow](https://www.gnu.org/software/stow/).
Each top-level package dir mirrors `$HOME`; stow symlinks its contents into place.

| Package  | Contents                                      |
| -------- | --------------------------------------------- |
| `zsh`    | `.zshrc`, `.zprofile`                         |
| `git`    | `.gitconfig`, `.config/git/ignore`            |
| `claude` | `.claude/settings.json`                       |
| `agents` | `.agents/skills/`, `.agents/.skill-lock.json` |

## Fresh machine

```sh
git clone git@github.com:hyamero/dotfiles.git
cd dotfiles
./install.sh
```

Installs Homebrew (if missing), runs `brew bundle`, backs up any conflicting
real files to `*.pre-stow`, stows all packages, and creates the
`~/.claude/skills` links on first run.

## Daily use

`~/.zshrc` etc. are symlinks into this repo — edit them as usual, then:

```sh
cd ~/Documents/Projects/personal/dotfiles
git add -A && git commit -m "..." && git push
```

## Adding a config

Place the file in a package dir mirroring its `$HOME` path, then re-stow:

```sh
cd ~/Documents/Projects/personal/dotfiles
stow -t "$HOME" --restow <package>
```

## Refresh Brewfile

```sh
brew bundle dump --file=Brewfile --force
```
