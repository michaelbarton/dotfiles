#!/usr/bin/env bash
# PostToolUse(Write|Edit) hook: review plan documents only.
# Path-gates first so non-plan edits exit silently, then prints the prompt
# from ../prompts/plan-review.md as additional_context for the main agent.

set -euo pipefail

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')

case "$file_path" in
  */.cursor/plans/*|*/.claude/plans/*) ;;
  *) exit 0 ;;
esac

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
prompt_file="$script_dir/../prompts/plan-review.md"

if [ ! -f "$prompt_file" ]; then
  echo "plan-review hook: missing prompt file at $prompt_file" >&2
  exit 1
fi

cat "$prompt_file"
