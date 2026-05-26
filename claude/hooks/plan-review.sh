#!/usr/bin/env bash
# PostToolUse(Write|Edit) hook: review plan documents.
# Path-gates first so non-plan edits exit silently, then assembles the prompt
# from ../prompts/plan-review.md with {{PLANNING_RULE}} substituted by the
# body of cursor/rules/planning.mdc (the canonical gate definitions).

set -euo pipefail

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')

case "$file_path" in
  */.cursor/plans/*|*/.claude/plans/*) ;;
  *) exit 0 ;;
esac

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
prompt_file="$script_dir/../prompts/plan-review.md"
planning_rule="$script_dir/../../cursor/rules/planning.mdc"

for f in "$prompt_file" "$planning_rule"; do
  if [ ! -f "$f" ]; then
    echo "plan-review hook: missing file $f" >&2
    exit 1
  fi
done

# Strip the YAML frontmatter (between the first two `---` lines) from the
# planning rule so only the rule body is injected.
planning_body=$(awk 'BEGIN{f=0} /^---$/{f++; next} f>=2{print}' "$planning_rule")

while IFS= read -r line || [ -n "$line" ]; do
  if [ "$line" = "{{PLANNING_RULE}}" ]; then
    printf '%s\n' "$planning_body"
  else
    printf '%s\n' "$line"
  fi
done < "$prompt_file"
