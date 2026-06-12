#!/usr/bin/env bash
# Stop hook: nag about build/render when, in the current turn:
#   - a .sql file was edited inside a dbt project (dbt_project.yml ancestor), or
#   - a .qmd file was edited (any location — quarto renders standalone files)
# AND no build/render command was run this turn.
#
# Reads the per-session state file written by track-tool-use.sh instead of
# parsing the transcript. A nag is delivered as {"decision": "block",
# "reason": ...} — the only output Claude Code feeds back to the model.
#
# Robustness invariants (this is a reminder, not an enforcement gate):
#   - Blocks at most ONCE per turn: when stop_hook_active is set (Claude is
#     already continuing because of this hook), clear state and allow the
#     stop unconditionally. We deliberately do not re-check whether the
#     build actually ran — re-checking is how agents get stuck in loops.
#   - Every error path fails open (exit 0, no block): missing/malformed
#     state file or fields, jq failures, unreadable input.

set -uo pipefail # no -e: error paths must fall through to allow the stop

input=$(cat) || exit 0
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null) || exit 0
[ -z "$session_id" ] && exit 0
case "$session_id" in
  *[!A-Za-z0-9_-]*) exit 0 ;;
esac

state_file="${TMPDIR:-/tmp}/claude-turn-${session_id}.jsonl"

stop_hook_active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null) || stop_hook_active=false
if [ "$stop_hook_active" = "true" ]; then
  rm -f "$state_file"
  exit 0
fi

[ -f "$state_file" ] || exit 0

edits=$(jq -r 'select(.tool == "Write" or .tool == "Edit") | .path // empty' \
  "$state_file" 2>/dev/null | grep -E '\.(sql|qmd)$') || edits=""

if [ -z "$edits" ]; then
  rm -f "$state_file"
  exit 0
fi

# Walk up from a directory looking for any of the given marker filenames.
# Returns 0 if any marker is found, 1 otherwise.
has_marker() {
  local dir="$1"
  shift
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    for marker in "$@"; do
      [ -f "$dir/$marker" ] && return 0
    done
    dir=$(dirname "$dir")
  done
  return 1
}

dbt_files=""
quarto_files=""

while IFS= read -r path; do
  [ -z "$path" ] && continue
  case "$path" in
    *.sql)
      if has_marker "$(dirname "$path")" dbt_project.yml; then
        dbt_files="${dbt_files}${path}"$'\n'
      fi
      ;;
    *.qmd)
      quarto_files="${quarto_files}${path}"$'\n'
      ;;
  esac
done <<<"$edits"

if [ -z "$dbt_files" ] && [ -z "$quarto_files" ]; then
  rm -f "$state_file"
  exit 0
fi

bashes=$(jq -r 'select(.tool == "Bash") | .cmd // empty' "$state_file" 2>/dev/null) || bashes=""

if printf '%s' "$bashes" | grep -qE '(just (build|html|render)|dbt (build|run|test)|quarto render)'; then
  rm -f "$state_file"
  exit 0
fi

# Keep the state file: the post-block stop is allowed via stop_hook_active,
# which also cleans it up.
reason=$(
  echo "You edited build-relevant files this turn but did not run a build/render command:"
  if [ -n "$dbt_files" ]; then
    echo
    echo "dbt project files (dbt_project.yml ancestor found):"
    printf '%s' "$dbt_files" | sed 's/^/  /'
    echo "  → run \`dbt build\` (or \`just build\` if the project has a justfile target)."
  fi
  if [ -n "$quarto_files" ]; then
    echo
    echo "quarto documents:"
    printf '%s' "$quarto_files" | sed 's/^/  /'
    echo "  → run \`quarto render <file>\` (or \`just html\`/\`just render\` if the project has it)."
  fi
  echo
  echo "Run the build/render now; if it fails, fix the failures before stopping, and report the result either way."
  echo "If a build is genuinely not applicable (e.g. the edit was comment-only or the file was deleted later in the turn), say why in one line instead."
)

jq -n --arg reason "$reason" '{decision: "block", reason: $reason}' 2>/dev/null || true
exit 0
