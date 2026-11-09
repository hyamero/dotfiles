#!/usr/bin/env bash
# PreToolUse (Bash): auto-approve plain pushes to origin, so a yes in chat isn't
# followed by a permission dialog. Approves by allowlisting parsed argv rather
# than pattern-matching flags: git accepts bundled short flags (-uf) and
# abbreviated long options (--mir), which permission-rule globs can't cover.
# Anything not approved here gets no decision and takes the normal permission
# flow (ask rules, auto-mode classifier).
command -v jq >/dev/null || exit 0

cmd="$(jq -r '.tool_input.command // empty')"

# One simple command only: no chaining, substitution, redirection or newlines.
case "$cmd" in *[\;\&\|\`\$\<\>\(\)\\\"\'\{\}]* | *$'\n'*) exit 0 ;; esac

read -ra argv <<<"$cmd"
[ "${argv[0]}" = git ] && [ "${argv[1]}" = push ] || exit 0

remote_seen=0
for arg in "${argv[@]:2}"; do
  case "$arg" in
    -u | --set-upstream) ;;
    origin) [ "$remote_seen" = 0 ] || exit 0; remote_seen=1 ;;
    -*) exit 0 ;;  # any other option, incl. bundles and abbreviations
    *)
      # A refspec needs the remote named first, so a URL or path can't pose as one.
      [ "$remote_seen" = 1 ] || exit 0
      # Plain src[:dst] names only; a leading + forces, a leading : deletes.
      [[ "$arg" =~ ^[A-Za-z0-9._/-]+(:[A-Za-z0-9._/-]+)?$ ]] || exit 0
      [[ "$arg" == -* ]] && exit 0 ;;
  esac
done

jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "allow",
  permissionDecisionReason: "plain push to origin (allow-safe-push.sh)"}}'
