# Nested shells (herdr panes, tmux) re-run the prepends below; keep PATH unique.
typeset -U path PATH

# Non-login shells skip .zprofile, so make sure brew is on PATH before
# anything below depends on it. Prefix differs per platform.
if ! command -v brew >/dev/null 2>&1; then
  for _brew in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x $_brew ]]; then eval "$($_brew shellenv)"; break; fi
  done
  unset _brew
fi

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git fzf z zsh-autosuggestions zsh-syntax-highlighting nvm npm bun)
source $ZSH/oh-my-zsh.sh

alias lg="lazygitrs"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
# Standalone pnpm lands in $PNPM_HOME on macOS but $PNPM_HOME/bin on Linux.
# Appended, not prepended, so corepack's shim still wins (see nvm note below).
export PATH="$PATH:$PNPM_HOME/bin"

# bun
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

[ -s "$HOME/.turso/env" ] && . "$HOME/.turso/env"
export PATH="$HOME/.local/bin:$PATH"

# Use nvm's default Node (24.x) so corepack's pnpm shim is on PATH ahead of the
# stale standalone pnpm. Must run after all PATH edits above.
nvm use default --silent 2>/dev/null

# WSL: a shell launched from the Windows side (`wsl` in PowerShell, an editor's
# integrated terminal, a multiplexer whose server started there) inherits the
# Windows cwd under /mnt/*, where every file op crosses the slow 9p bridge.
# Start in $HOME instead. Interactive only, so `wsl -- <cmd>` still runs in the
# directory it was invoked from.
if [[ -o interactive && -n "$WSL_DISTRO_NAME" && "$PWD" == /mnt/* ]]; then
  cd "$HOME"
fi

# Machine-local overrides (untracked, gitignored via *.local).
[ -s "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
