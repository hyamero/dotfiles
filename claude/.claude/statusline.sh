#!/bin/sh
# Claude Code status line mirroring the Oh My Zsh robbyrussell prompt:
#   ➜  <dir> git:(<branch>) ✗
# Colors and layout are lifted from robbyrussell.zsh-theme so the status line
# reads the same as the shell prompt in the pane above it.
#
# Responsive: renders the richest tier that fits $COLUMNS, shedding detail in
# order: bars shrink, bars go, model goes, git part goes. Usage numbers stay.

payload=$(cat)

# Every field is parsed with jq; without it, show the directory alone rather
# than a line of errors.
if ! command -v jq >/dev/null 2>&1; then
  printf '%s' "$(basename "$PWD")"
  exit 0
fi

dir=$(printf '%s' "$payload" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(printf '%s' "$payload" | jq -r '.model.display_name // empty')
[ -n "$dir" ] || dir=$PWD

bgreen='\033[1;32m'; cyan='\033[36m'; bblue='\033[1;34m'
red='\033[31m'; green='\033[32m'; blue='\033[34m'; yellow='\033[33m'; dim='\033[2m'; reset='\033[0m'
sep=" ${dim}│${reset} "

# %c in the theme: trailing component of the cwd only.
dirname=$(basename "$dir")

# Detached HEAD falls back to a tag, then a short SHA, matching git_prompt_info.
git_part=""
if branch=$(git -C "$dir" symbolic-ref --quiet --short HEAD 2>/dev/null) \
  || branch=$(git -C "$dir" describe --tags --exact-match HEAD 2>/dev/null) \
  || branch=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null); then
  git_part=" ${bblue}git:(${red}${branch}${reset}"
  if [ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ]; then
    git_part="${git_part}${blue}) ${yellow}✗${reset}"
  else
    git_part="${git_part}${blue})${reset}"
  fi
fi

# Absent when the model doesn't support the effort parameter.
effort=$(printf '%s' "$payload" | jq -r '.effort.level // empty')
case $effort in
  low) pips='●○○○○' ;; medium) pips='●●○○○' ;; high) pips='●●●○○' ;;
  xhigh) pips='●●●●○' ;; max) pips='●●●●●' ;; *) pips='' ;;
esac

# Null until the session's first API response.
ctx=$(printf '%s' "$payload" | jq -r '.context_window.used_percentage // empty | floor')

# rate_limits only exists for Pro/Max subscribers.
five=$(printf '%s' "$payload" | jq -r '.rate_limits.five_hour.used_percentage // empty | floor')
if [ -n "$five" ]; then
  # The label is the countdown to the window's reset: whole hours, then minutes
  # in the last hour. Falls back to "5h" without a usable resets_at.
  # Shell arithmetic rather than `date -r`/`date -d`, which differ between
  # macOS and GNU.
  label="5h"
  resets=$(printf '%s' "$payload" | jq -r '.rate_limits.five_hour.resets_at // empty')
  if [ -n "$resets" ]; then
    left=$((resets - $(date +%s)))
    if [ "$left" -ge 3600 ]; then
      label="$((left / 3600))h"
    elif [ "$left" -gt 0 ]; then
      m=$((left / 60)); [ "$m" -lt 1 ] && m=1
      label="${m}m"
    fi
  fi
fi

# Green while comfortable, then yellow at 50% and red at 80%.
pct_color() {
  if [ "$1" -ge 80 ]; then printf '%s' "$red"
  elif [ "$1" -ge 50 ]; then printf '%s' "$yellow"
  else printf '%s' "$green"; fi
}

# meter <pct> <cells>: coloured fill on a dim track, then the percentage; 0 cells
# prints the percentage alone. Any non-zero usage gets at least one cell so it
# never reads as empty.
meter() {
  _c=$(pct_color "$1")
  if [ "$2" -eq 0 ]; then printf '%s' "${_c}$1%${reset}"; return; fi
  _fill=$(( ($1 * $2 + 50) / 100 ))
  [ "$_fill" -gt "$2" ] && _fill=$2
  [ "$1" -gt 0 ] && [ "$_fill" -eq 0 ] && _fill=1
  _bar=""; _i=0
  while [ "$_i" -lt "$2" ]; do
    [ "$_i" -eq "$_fill" ] && _bar="${_bar}${reset}${dim}"
    if [ "$_i" -lt "$_fill" ]; then _bar="${_bar}━"; else _bar="${_bar}─"; fi
    _i=$((_i + 1))
  done
  printf '%s' "${_c}${_bar}${reset} ${_c}$1%${reset}"
}

# render <tier>: 0 widest … 4 narrowest.
render() {
  case $1 in 0) _cells=10 ;; 1) _cells=5 ;; *) _cells=0 ;; esac
  if [ "$1" -ge 4 ]; then
    _l="${cyan}${dirname}${reset}"
  else
    _l="${bgreen}➜${reset}  ${cyan}${dirname}${reset}${git_part}"
  fi
  _m=""
  [ "$1" -le 2 ] && [ -n "$model" ] && _m="${dim}${model}${reset}"
  if [ -n "$effort" ] && [ "$1" -le 3 ]; then
    _e="${dim}${effort}${reset}"
    [ "$1" -eq 0 ] && [ -n "$pips" ] && _e="${cyan}${pips}${reset} ${_e}"
    _m="${_m:+${_m} }${_e}"
  fi
  [ -n "$_m" ] && _l="${_l}${sep}${_m}"
  [ -n "$ctx" ] && _l="${_l}${sep}${dim}ctx${reset} $(meter "$ctx" "$_cells")"
  [ -n "$five" ] && _l="${_l}${sep}${dim}${label}${reset} $(meter "$five" "$_cells")"
  printf '%s' "$_l"
}

# Visible width: colour codes are still literal `\033[…m` text here, so strip
# them before counting; jq counts code points, which every glyph used is.
width() {
  printf '%s' "$1" | jq -Rrs 'gsub("\\\\033\\[[0-9;]*m"; "") | length'
}

# COLUMNS is set by Claude Code (tput can't see the terminal from here). The
# 2-column margin leaves room for the status row's padding.
max=$(( ${COLUMNS:-0} - 2 ))
tier=0
line=$(render 0)
if [ "${COLUMNS:-0}" -gt 0 ]; then
  while [ "$tier" -lt 4 ] && [ "$(width "$line")" -gt "$max" ]; do
    tier=$((tier + 1))
    line=$(render "$tier")
  done
fi

printf '%b' "$line"
