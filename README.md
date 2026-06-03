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
real files to `*.pre-stow`, stows all packages, creates the `~/.claude/skills`
links on first run, and reinstalls the Claude plugins listed in
`settings.json` (if the `claude` CLI is present).

> Plugins themselves aren't tracked — only the enabled list in
> `settings.json`. `install.sh` reinstalls them from the built-in
> `claude-plugins-official` marketplace. Run it again after installing Claude
> Code if the CLI wasn't available the first time.

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
brew bundle dump --file=Brewfile --force --no-vscode
```

VS Code extensions are intentionally excluded (synced via VS Code Settings
Sync) — `--no-vscode` keeps them out on refresh.
