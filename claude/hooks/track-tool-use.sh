#!/usr/bin/env bash
# PostToolUse(Write|Edit|Bash) hook: append this turn's tool uses to a
# per-session state file so the Stop hook (stop-check.sh) can see which
# files were edited and which commands ran without parsing the transcript.
# Never blocks anything: no output, always exits 0.

set -uo pipefail

input=$(cat) || exit 0
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null) || exit 0
[ -z "$session_id" ] && exit 0

# Session id becomes part of a filename; accept only safe characters.
case "$session_id" in
  *[!A-Za-z0-9_-]*) exit 0 ;;
esac

printf '%s' "$input" | jq -c '{
  tool: .tool_name,
  path: (.tool_input.file_path // null),
  cmd: (.tool_input.command // null)
}' >>"${TMPDIR:-/tmp}/claude-turn-${session_id}.jsonl" 2>/dev/null || true

exit 0
