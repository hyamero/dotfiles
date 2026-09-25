#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(zsh git claude agents ghostty)

# herdr's prefix key differs per platform and its config has no include or
# conditional support, so the two variants ship as separate stow packages.
# Both provide .config/herdr/config.toml, so exactly one may be stowed.
if [ "$(uname -s)" = "Darwin" ]; then
  PACKAGES+=(herdr)
else
  PACKAGES+=(herdr-linux)
fi

# The two variants must stay identical apart from the prefix line -- compare
# them with comments, blanks and the prefix stripped out.
herdr_body() { grep -vE '^[[:space:]]*(#|$)' "$1" | grep -v '^prefix = '; }
if ! diff <(herdr_body "$DOTFILES_DIR/herdr/.config/herdr/config.toml") \
          <(herdr_body "$DOTFILES_DIR/herdr-linux/.config/herdr/config.toml") >/dev/null; then
  echo "warning: herdr and herdr-linux config.toml have drifted apart" >&2
  echo "         (they must differ only in [keys] prefix)" >&2
fi

# 1. Homebrew. Install prefix differs per platform: /opt/homebrew on Apple
#    Silicon, /home/linuxbrew/.linuxbrew on Linux/WSL. The installer does not
#    put brew on PATH for the current shell, so source shellenv from whichever
#    prefix it created.
if ! command -v brew >/dev/null 2>&1; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  for prefix in /opt/homebrew /home/linuxbrew/.linuxbrew; do
    if [ -x "$prefix/bin/brew" ]; then eval "$("$prefix/bin/brew" shellenv)"; break; fi
  done
fi

# 2. Packages (includes stow). Casks are macOS-only and abort the whole bundle
#    run on Linux, so they live in a separate Brewfile.macos.
brew bundle --file="$DOTFILES_DIR/Brewfile"
if [ "$(uname -s)" = "Darwin" ] && [ -f "$DOTFILES_DIR/Brewfile.macos" ]; then
  brew bundle --file="$DOTFILES_DIR/Brewfile.macos"
fi

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
#    generated from installed_plugins.json (see AGENTS.md) — we don't read
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

# 6. Git identity lives in the untracked ~/.gitconfig.local, not the repo.
if [ -z "$(git config --global user.email)" ]; then
  echo "note: no git identity set. Add one to ~/.gitconfig.local:"
  echo '  git config --file ~/.gitconfig.local user.name "Your Name"'
  echo '  git config --file ~/.gitconfig.local user.email you@example.com'
  echo '  git config --file ~/.gitconfig.local user.signingkey ~/.ssh/id_ed25519.pub'
fi

echo "done. open a new shell to pick up zsh config."
