#!/usr/bin/env bash
# PreToolUse (Bash): auto-approve plain pushes to origin, so a yes in chat isn't
# followed by a permission dialog. "Plain" means the checked-out branch to its
# same-named branch on origin and nothing else. Approves by allowlisting parsed
# argv rather than pattern-matching flags: git accepts bundled short flags (-uf)
# and abbreviated long options (--mir), which permission-rule globs can't cover.
# Anything not approved here gets no decision and takes the normal permission
# flow (ask rules, auto-mode classifier).
command -v jq >/dev/null || exit 0

input="$(cat)"
cmd="$(jq -r '.tool_input.command // empty' <<<"$input")"
cwd="$(jq -r '.cwd // empty' <<<"$input")"

# One simple command only: no chaining, substitution, redirection or newlines.
case "$cmd" in *[\;\&\|\`\$\<\>\(\)\\\"\'\{\}]* | *$'\n'*) exit 0 ;; esac

read -ra argv <<<"$cmd"
[ "${argv[0]}" = git ] && [ "${argv[1]}" = push ] || exit 0

remote="" refspec="" positional=0
for arg in "${argv[@]:2}"; do
  case "$arg" in
    -u | --set-upstream) ;;
    -*) exit 0 ;;  # any other option, incl. bundles and abbreviations
    *)
      positional=$((positional + 1))
      case "$positional" in 1) remote="$arg" ;; 2) refspec="$arg" ;; *) exit 0 ;; esac ;;
  esac
done

g() { git -C "${cwd:-.}" "$@" 2>/dev/null; }

# Detached HEAD has no branch to check the destination against.
branch="$(g symbolic-ref --quiet --short HEAD)" || exit 0
# A branch may be named "+x", and pushing that name as a refspec is a force push.
[[ "$branch" =~ ^[A-Za-z0-9._/-]+$ ]] || exit 0

# No remote named: resolve the one git would pick, which need not be origin.
if [ -z "$remote" ]; then
  remote="$(g config "branch.$branch.pushRemote" || g config remote.pushDefault \
    || g config "branch.$branch.remote" || echo origin)"
fi
[ "$remote" = origin ] || exit 0

case "$refspec" in
  HEAD | "$branch") ;;
  "")
    # No refspec: config picks the destination, and only simple/current are
    # guaranteed to mean "this branch, same name".
    case "$(g config push.default || echo simple)" in simple | current) ;; *) exit 0 ;; esac
    [ -z "$(g config --get-all remote.origin.push)" ] || exit 0 ;;
  # src:dst can land a feature branch on main; any other bare name is a tag
  # or a different branch.
  *) exit 0 ;;
esac

jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "allow",
  permissionDecisionReason: "plain push to origin (allow-safe-push.sh)"}}'
