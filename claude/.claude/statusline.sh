#!/bin/sh
# Claude Code status line mirroring the Oh My Zsh robbyrussell prompt:
#   ➜  <dir> git:(<branch>) ✗
# Colors and layout are lifted from robbyrussell.zsh-theme so the status line
# reads the same as the shell prompt in the pane above it.

payload=$(cat)

dir=$(printf '%s' "$payload" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(printf '%s' "$payload" | jq -r '.model.display_name // empty')
[ -n "$dir" ] || dir=$PWD

bgreen='\033[1;32m'; cyan='\033[36m'; bblue='\033[1;34m'
red='\033[31m'; blue='\033[34m'; yellow='\033[33m'; dim='\033[2m'; reset='\033[0m'

# %c in the theme: trailing component of the cwd only.
line="${bgreen}➜${reset}  ${cyan}$(basename "$dir")${reset}"

# Detached HEAD falls back to a tag, then a short SHA, matching git_prompt_info.
if branch=$(git -C "$dir" symbolic-ref --quiet --short HEAD 2>/dev/null) \
  || branch=$(git -C "$dir" describe --tags --exact-match HEAD 2>/dev/null) \
  || branch=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null); then
  line="${line} ${bblue}git:(${red}${branch}${reset}"
  if [ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ]; then
    line="${line}${blue}) ${yellow}✗${reset}"
  else
    line="${line}${blue})${reset}"
  fi
fi

[ -n "$model" ] && line="${line} ${dim}${model}${reset}"

printf '%b' "$line"
