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
red='\033[31m'; green='\033[32m'; blue='\033[34m'; yellow='\033[33m'; dim='\033[2m'; reset='\033[0m'

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

sep=" ${dim}│${reset} "

[ -n "$model" ] && line="${line}${sep}${dim}${model}${reset}"

# Absent when the model doesn't support the effort parameter.
effort=$(printf '%s' "$payload" | jq -r '.effort.level // empty')
case $effort in
  low) pips='●○○○○' ;; medium) pips='●●○○○' ;; high) pips='●●●○○' ;;
  xhigh) pips='●●●●○' ;; max) pips='●●●●●' ;; *) pips='' ;;
esac
if [ -n "$pips" ]; then
  line="${line} ${cyan}${pips}${reset} ${dim}${effort}${reset}"
elif [ -n "$effort" ]; then
  line="${line} ${dim}${effort}${reset}"
fi

# Green while comfortable, then yellow at 50% and red at 80%.
pct_color() {
  if [ "$1" -ge 80 ]; then printf '%s' "$red"
  elif [ "$1" -ge 50 ]; then printf '%s' "$yellow"
  else printf '%s' "$green"; fi
}

# 10-cell meter: coloured fill on a dim track. Any non-zero usage gets at least
# one cell so it never reads as empty.
meter() {
  _fill=$(( ($1 * 10 + 50) / 100 ))
  [ "$_fill" -gt 10 ] && _fill=10
  [ "$1" -gt 0 ] && [ "$_fill" -eq 0 ] && _fill=1
  _bar=""; _i=0
  while [ "$_i" -lt 10 ]; do
    [ "$_i" -eq "$_fill" ] && _bar="${_bar}${reset}${dim}"
    if [ "$_i" -lt "$_fill" ]; then _bar="${_bar}━"; else _bar="${_bar}─"; fi
    _i=$((_i + 1))
  done
  _c=$(pct_color "$1")
  printf '%s' "${_c}${_bar}${reset} ${_c}$1%${reset}"
}

# Null until the session's first API response, so both blocks may be skipped.
ctx=$(printf '%s' "$payload" | jq -r '.context_window.used_percentage // empty | floor')
[ -n "$ctx" ] && line="${line}${sep}${dim}ctx${reset} $(meter "$ctx")"

# rate_limits only exists for Pro/Max subscribers.
five=$(printf '%s' "$payload" | jq -r '.rate_limits.five_hour.used_percentage // empty | floor')
if [ -n "$five" ]; then
  line="${line}${sep}${dim}5h${reset} $(meter "$five")"
  # Countdown via shell arithmetic rather than `date -r`/`date -d`, which differ
  # between macOS and GNU.
  resets=$(printf '%s' "$payload" | jq -r '.rate_limits.five_hour.resets_at // empty')
  if [ -n "$resets" ]; then
    left=$((resets - $(date +%s)))
    if [ "$left" -gt 0 ]; then
      h=$((left / 3600)); m=$((left % 3600 / 60))
      if [ "$h" -gt 0 ]; then left="${h}h${m}m"; else left="${m}m"; fi
      line="${line} ${dim}↻ ${left}${reset}"
    fi
  fi
fi

printf '%b' "$line"
