#!/usr/bin/env bash
# Desktop-notify me when a session is blocked on my input, so a handoff doesn't
# sit unseen in a background pane. Wired to:
#   PreToolUse   mcp__browse__execute (only when the code calls handoff()),
#                AskUserQuestion, ExitPlanMode
#   Notification permission_prompt, idle_prompt, elicitation_dialog
# idle_prompt is the catch-all: it fires when a turn ended and I haven't
# replied, which covers "please log in, then tell me" written as plain text.
command -v jq >/dev/null || exit 0

input="$(cat)"
event="$(jq -r '.hook_event_name // empty' <<<"$input")"
tool="$(jq -r '.tool_name // empty' <<<"$input")"
project="$(basename "$(jq -r '.cwd // empty' <<<"$input")")"

case "$event:$tool" in
  PreToolUse:mcp__browse__execute)
    # Every execute call matches the matcher; only a handoff blocks on me.
    code="$(jq -r '[.tool_input | .. | strings] | join("\n")' <<<"$input")"
    grep -q 'handoff(' <<<"$code" || exit 0
    msg="$(grep -oE "handoff\([[:space:]]*[\"'\`][^\"'\`]+" <<<"$code" | head -1 | sed -E "s/^handoff\([[:space:]]*.//")"
    title="Browser handoff"
    body="${msg:-The browser needs you}" ;;
  PreToolUse:AskUserQuestion)
    title="Question waiting"
    body="$(jq -r '.tool_input.questions[0].question // "Claude has a question"' <<<"$input")" ;;
  PreToolUse:ExitPlanMode)
    title="Plan ready"
    body="Review the plan" ;;
  Notification:*)
    title="Claude needs you"
    body="$(jq -r '.message // "Waiting for input"' <<<"$input")" ;;
  *) exit 0 ;;
esac

[ -n "$project" ] && title="$title · $project"
body="${body:0:200}"

if [ "${HERDR_ENV:-}" = "1" ] && command -v herdr >/dev/null; then
  herdr notification show "$title" --body "$body" --sound request >/dev/null
  # Float this workspace to the top of the sidebar so the one waiting on me is
  # first. The CLI has no `workspace move`, so call the socket API directly.
  ws="${HERDR_WORKSPACE_ID:-${HERDR_PANE_ID%%:*}}"
  if [ -n "$ws" ] && [ -n "${HERDR_SOCKET_PATH:-}" ] && command -v python3 >/dev/null; then
    # -I: hooks run in the session's cwd; keep a repo's json.py etc. off sys.path.
    python3 -I - "$ws" <<'PY' || true
import json, os, socket, sys
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.settimeout(1)
s.connect(os.environ["HERDR_SOCKET_PATH"])
req = {"id": "notify-blocked", "method": "workspace.move",
       "params": {"workspace_id": sys.argv[1], "insert_index": 0}}
s.sendall((json.dumps(req) + "\n").encode())
s.recv(65536)
PY
  fi
elif [ "$(uname -s)" = "Darwin" ]; then
  # Pass text as argv so quotes in the message can't break the AppleScript.
  osascript -e 'on run a' -e 'display notification (item 2 of a) with title (item 1 of a) sound name "Glass"' -e 'end run' "$title" "$body"
fi
exit 0
