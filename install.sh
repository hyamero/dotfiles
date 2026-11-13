#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(zsh git claude agents)

# herdr's prefix key differs per platform and its config has no include or
# conditional support, so the two variants ship as separate stow packages.
# Both provide .config/herdr/config.toml, so exactly one may be stowed.
# Ghostty has no Linux build to run under WSL, so it's macOS-only too.
if [ "$(uname -s)" = "Darwin" ]; then
  PACKAGES+=(herdr ghostty)
else
  PACKAGES+=(herdr-linux)
fi

# The two variants must stay identical apart from the prefix line -- compare
# them with comments, blanks and the prefix stripped out.
# Direct cmd nav is macOS-only (see herdr config), so skip it when comparing.
herdr_body() { grep -vE '^[[:space:]]*(#|$)' "$1" | grep -v '^prefix = ' | grep -v '"cmd+'; }
if ! diff <(herdr_body "$DOTFILES_DIR/herdr/.config/herdr/config.toml") \
          <(herdr_body "$DOTFILES_DIR/herdr-linux/.config/herdr/config.toml") >/dev/null; then
  echo "warning: herdr and herdr-linux config.toml have drifted apart" >&2
  echo "         (they must differ only in [keys] prefix and the macOS-only cmd nav)" >&2
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
#    A failed formula (flaky download, a tap Linux brew won't trust yet) must
#    not stop the steps below: they only need stow, which is checked for here.
bundle() {
  brew bundle --file="$1" \
    || echo "warning: brew bundle left $(basename "$1") incomplete; fix the failures above and re-run" >&2
}
bundle "$DOTFILES_DIR/Brewfile"
if [ "$(uname -s)" = "Darwin" ] && [ -f "$DOTFILES_DIR/Brewfile.macos" ]; then
  bundle "$DOTFILES_DIR/Brewfile.macos"
fi
command -v stow >/dev/null 2>&1 || { echo "error: stow is not installed; cannot continue" >&2; exit 1; }

# nvm keeps installed Node versions in $NVM_DIR. Without ~/.nvm the Oh My Zsh
# plugin falls back to the Homebrew keg, which `brew upgrade nvm` wipes.
mkdir -p "$HOME/.nvm"

# 2b. Oh My Zsh and the custom plugins .zshrc loads; without them every new
#     shell errors out. --keep-zshrc stops the installer replacing the stowed
#     .zshrc, RUNZSH=no stops it dropping into a shell mid-script.
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
fi
omz_plugins="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
for repo in zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting; do
  [ -d "$omz_plugins/${repo#*/}" ] || git clone --depth 1 "https://github.com/$repo" "$omz_plugins/${repo#*/}"
done

# 3. Back up conflicting files (real files, foreign or dangling symlinks),
#    then stow each package. Skip paths that already resolve to the repo
#    file (-ef): already stowed, directly or through a folded dir symlink.
backup_conflicts() {
  local pkg="$1" rel target backup n
  while IFS= read -r rel; do
    target="$HOME/${rel#./}"
    if { [ -e "$target" ] || [ -L "$target" ]; } \
      && ! [ "$target" -ef "$DOTFILES_DIR/$pkg/$rel" ]; then
      # Never overwrite an earlier backup. The counter goes before the suffix
      # so the name still matches *.pre-stow (.gitignore, .stow-local-ignore).
      backup="$target.pre-stow" n=1
      while [ -e "$backup" ] || [ -L "$backup" ]; do
        backup="$target.$n.pre-stow" n=$((n + 1))
      done
      mv "$target" "$backup"
      echo "backed up: $target -> $backup"
    fi
  done < <(cd "$DOTFILES_DIR/$pkg" && find . -type f ! -name .stow-local-ignore)
}

# Pre-create so stow links files into these rather than folding the whole dir
# into the repo, where herdr would then drop its untracked hook script and its
# runtime state (logs, sockets, session.json), and git its credentials file.
mkdir -p "$HOME/.claude/hooks" "$HOME/.config/herdr" "$HOME/.config/git"

for pkg in "${PACKAGES[@]}"; do
  backup_conflicts "$pkg"
  stow -d "$DOTFILES_DIR" -t "$HOME" --restow "$pkg"
  echo "stowed: $pkg"
done

# 4. Claude skill glue: ~/.claude/skills is a real dir of relative symlinks
#    into ~/.agents/skills. Only missing links are added, so re-running picks
#    up new skills without touching existing entries. Glue links whose skill
#    is gone are dropped; dangling links pointing anywhere else are left alone.
mkdir -p "$HOME/.claude/skills"
shopt -s nullglob
for link in "$HOME"/.claude/skills/*; do
  if [ -L "$link" ] && [ ! -e "$link" ]; then
    case "$(readlink "$link")" in
      ../../.agents/skills/*) rm "$link"; echo "pruned skill link: $(basename "$link")" ;;
    esac
  fi
done
for skill in "$HOME"/.agents/skills/*/; do
  name="$(basename "$skill")"
  link="$HOME/.claude/skills/$name"
  if [ ! -e "$link" ] && [ ! -L "$link" ]; then
    ln -s "../../.agents/skills/$name" "$link"
    echo "linked skill: $name"
  fi
done
shopt -u nullglob

# 5. Claude plugins: reinstall the tracked list. claude-plugins.list is
#    generated from installed_plugins.json (see AGENTS.md) — we don't read
#    settings.json's enabledPlugins, which Claude Code auto-manages and prunes.
#    The claude-plugins-official marketplace is built-in, no registration needed.
#    Skipped (with a note) if the claude CLI isn't installed yet.
if command -v claude >/dev/null 2>&1; then
  if [ -f "$DOTFILES_DIR/claude-plugins.list" ]; then
    # The list includes plugins kept installed but disabled, and installing
    # writes enabledPlugins through the stowed settings.json into the repo.
    # The tracked on/off state wins, so put the file back if it changed.
    settings="$DOTFILES_DIR/claude/.claude/settings.json"
    settings_before="$(mktemp)"
    cp "$settings" "$settings_before"
    skip='^[[:space:]]*(#|$)'
    while IFS= read -r plugin || [ -n "$plugin" ]; do
      [[ "$plugin" =~ $skip ]] && continue
      # </dev/null: claude must not read the rest of the list as its stdin.
      claude plugin install "$plugin" --scope user </dev/null || echo "warning: failed to install $plugin"
    done < "$DOTFILES_DIR/claude-plugins.list"
    if ! cmp -s "$settings_before" "$settings"; then
      # cat, not mv: the path must stay the file stow links to.
      cat "$settings_before" > "$settings"
      echo "restored settings.json: plugin install had changed it"
    fi
    rm -f "$settings_before"
  fi
else
  echo "note: claude CLI not found — skipping plugin install. Re-run this script after installing Claude Code to restore plugins."
fi

# 6. Git identity lives in the untracked ~/.gitconfig.local, not the repo.
#    --includes: --global alone reads ~/.gitconfig without following [include].
if [ -z "$(git config --global --includes user.email || true)" ]; then
  echo "note: no git identity set. Add one to ~/.gitconfig.local:"
  echo '  git config --file ~/.gitconfig.local user.name "Your Name"'
  echo '  git config --file ~/.gitconfig.local user.email you@example.com'
  echo '  git config --file ~/.gitconfig.local user.signingkey ~/.ssh/id_ed25519.pub'
fi

# 7. Pre-commit hook (lefthook.yml): refuses commits that add an absolute home
#    path, which would break the other machine.
if command -v lefthook >/dev/null 2>&1; then
  (cd "$DOTFILES_DIR" && lefthook install) || echo "warning: lefthook install failed" >&2
fi

echo "done. open a new shell to pick up zsh config."
