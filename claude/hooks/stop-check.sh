#!/usr/bin/env bash
# Stop hook: nag about build/render only when, in the current turn:
#   - a .sql file was edited inside a dbt project (dbt_project.yml ancestor), or
#   - a .qmd file was edited (any location — quarto renders standalone files)
# AND no build/render command was run this turn.

set -euo pipefail

input=$(cat)
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')

if [ -z "$transcript" ] || [ ! -f "$transcript" ]; then
  exit 0
fi

last_user_line=$(grep -n '"type":"user"' "$transcript" | tail -1 | cut -d: -f1)
last_user_line=${last_user_line:-0}
recent=$(tail -n +"$((last_user_line + 1))" "$transcript")

edits=$(printf '%s' "$recent" | jq -r '
  select(.type == "assistant") |
  .message.content[]? |
  select(.type == "tool_use") |
  select(.name == "Write" or .name == "Edit") |
  .input.file_path // empty
' 2>/dev/null | grep -E '\.(sql|qmd)$' || true)

if [ -z "$edits" ]; then
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
done <<< "$edits"

if [ -z "$dbt_files" ] && [ -z "$quarto_files" ]; then
  exit 0
fi

bashes=$(printf '%s' "$recent" | jq -r '
  select(.type == "assistant") |
  .message.content[]? |
  select(.type == "tool_use" and .name == "Bash") |
  .input.command // empty
' 2>/dev/null || true)

if printf '%s' "$bashes" | grep -qE '(just (build|html|render)|dbt (build|run|test)|quarto render)'; then
  exit 0
fi

{
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
  echo "Verify before stopping."
}
