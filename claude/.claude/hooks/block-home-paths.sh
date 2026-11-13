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
# A new file's directory may not exist yet; ask git from the nearest one that does.
dir="$(dirname "$real")"
while [ ! -d "$dir" ] && [ "$dir" != / ] && [ "$dir" != . ]; do dir="$(dirname "$dir")"; done
top="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -f "$top/claude/.claude/settings.json" ] && [ -f "$top/install.sh" ] || exit 0
# The pattern lives in the repo so the pre-commit check uses the same one.
[ -x "$top/scripts/home-paths.sh" ] || exit 0

new="$(jq -r '[.tool_input.content, .tool_input.new_string, (.tool_input.edits // [] | .[].new_string)] | map(select(. != null)) | join("\n")' <<<"$input")"

hits="$("$top/scripts/home-paths.sh" <<<"$new")"
[ -z "$hits" ] && exit 0

{
  echo "Blocked: absolute home path in $file: $(echo $hits)"
  echo "This repo is stowed on a Mac and a WSL box with different homes."
  echo "Use \$HOME in shell and settings.json, ~ in .gitconfig (see AGENTS.md)."
} >&2
exit 2
