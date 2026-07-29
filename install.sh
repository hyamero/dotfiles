#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(zsh git claude agents herdr)

# 1. Homebrew (Apple Silicon path)
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 2. Packages (includes stow)
brew bundle --file="$DOTFILES_DIR/Brewfile"

# 3. Back up conflicting files (real files, foreign or dangling symlinks),
#    then stow each package. Skip paths that already resolve to the repo
#    file (-ef): already stowed, directly or through a folded dir symlink.
backup_conflicts() {
  local pkg="$1" rel target
  while IFS= read -r rel; do
    target="$HOME/${rel#./}"
    if { [ -e "$target" ] || [ -L "$target" ]; } \
      && ! [ "$target" -ef "$DOTFILES_DIR/$pkg/$rel" ]; then
      mv "$target" "$target.pre-stow"
      echo "backed up: $target -> $target.pre-stow"
    fi
  done < <(cd "$DOTFILES_DIR/$pkg" && find . -type f)
}

for pkg in "${PACKAGES[@]}"; do
  backup_conflicts "$pkg"
  stow -d "$DOTFILES_DIR" -t "$HOME" --restow "$pkg"
  echo "stowed: $pkg"
done

# 4. Claude skill glue: ~/.claude/skills is a real dir of relative symlinks
#    into ~/.agents/skills (only created if missing — existing setups untouched)
if [ ! -d "$HOME/.claude/skills" ]; then
  mkdir -p "$HOME/.claude/skills"
  shopt -s nullglob
  for skill in "$HOME"/.agents/skills/*/; do
    name="$(basename "$skill")"
    ln -s "../../.agents/skills/$name" "$HOME/.claude/skills/$name"
    echo "linked skill: $name"
  done
  shopt -u nullglob
fi

# 5. Claude plugins: reinstall the tracked list. claude-plugins.list is
#    generated from installed_plugins.json (see README) — we don't read
#    settings.json's enabledPlugins, which Claude Code auto-manages and prunes.
#    The claude-plugins-official marketplace is built-in, no registration needed.
#    Skipped (with a note) if the claude CLI isn't installed yet.
if command -v claude >/dev/null 2>&1; then
  if [ -f "$DOTFILES_DIR/claude-plugins.list" ]; then
    grep -vE '^[[:space:]]*(#|$)' "$DOTFILES_DIR/claude-plugins.list" \
      | while IFS= read -r plugin; do
          claude plugin install "$plugin" --scope user || echo "warning: failed to install $plugin"
        done
  fi
else
  echo "note: claude CLI not found — skipping plugin install. Re-run this script after installing Claude Code to restore plugins."
fi

echo "done. open a new shell to pick up zsh config."
