#!/usr/bin/env bash
# PreToolUse (Edit|Write|MultiEdit): refuse writes that put an absolute home
# path into a file of the dotfiles repo. The repo is shared by a Mac and a WSL
# box with different homes, so such a path silently breaks the other machine.
command -v jq >/dev/null || exit 0

input="$(cat)"
file="$(jq -r '.tool_input.file_path // empty' <<<"$input")"
[ -n "$file" ] || exit 0

# Docs may quote paths as examples.
case "$file" in *.md) exit 0 ;; esac

# Resolve symlinks: ~/.claude/settings.json is stowed into the repo.
real="$(realpath "$file" 2>/dev/null || echo "$file")"
top="$(git -C "$(dirname "$real")" rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -f "$top/claude/.claude/settings.json" ] && [ -f "$top/install.sh" ] || exit 0

new="$(jq -r '[.tool_input.content, .tool_input.new_string, (.tool_input.edits // [] | .[].new_string)] | map(select(. != null)) | join("\n")' <<<"$input")"

# /home/linuxbrew is Linux Homebrew's fixed prefix, not a user home.
hits="$(grep -oE '/(Users|home)/[A-Za-z0-9._-]+' <<<"$new" | grep -v '^/home/linuxbrew$' | sort -u)"
[ -z "$hits" ] && exit 0

{
  echo "Blocked: absolute home path in $file: $(echo $hits)"
  echo "This repo is stowed on a Mac and a WSL box with different homes."
  echo "Use \$HOME in shell and settings.json, ~ in .gitconfig (see AGENTS.md)."
} >&2
exit 2
