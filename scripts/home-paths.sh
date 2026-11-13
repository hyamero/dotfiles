#!/usr/bin/env bash
# Find absolute home paths, which break whichever machine has the other home.
#   home-paths.sh            print the home paths found on stdin, one per line
#   home-paths.sh --staged   exit 1 if the staged diff adds one (pre-commit)
# The Claude Code hook block-home-paths.sh calls the stdin form, so the hook and
# the pre-commit check share one pattern.

scan() {
  # A path starts the line or follows a delimiter (space, quote, =, :), which
  # skips URL segments such as https://host/home/docs. Linux Homebrew's fixed
  # prefix and the Mac's shared folder are the same on every machine.
  grep -oE '(^|[^A-Za-z0-9._~/-])/(Users|home)/[A-Za-z0-9._-]+' \
    | grep -oE '/(Users|home)/.*' \
    | grep -vxE '/home/linuxbrew|/Users/(Shared)' \
    | sort -u
}

if [ "${1:-}" != --staged ]; then
  scan
  exit 0
fi

# Added lines only. Docs are excluded: they may quote paths as examples.
hits="$(git diff --cached -U0 --no-color --diff-filter=ACMR -- . ':(exclude)*.md' \
  | grep '^+' | grep -v '^+++ ' | scan)"
[ -z "$hits" ] && exit 0

{
  echo "Blocked: staged changes add an absolute home path: $(echo $hits)"
  echo "This repo is stowed on a Mac and a WSL box with different homes."
  echo "Use \$HOME in shell and settings.json, ~ in .gitconfig (see AGENTS.md)."
} >&2
exit 1
