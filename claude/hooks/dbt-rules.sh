#!/usr/bin/env bash
# PostToolUse(Write|Edit) hook: inject dbt conventions (cursor/rules/dbt.mdc)
# when a .sql/.yml file inside a dbt project (dbt_project.yml ancestor) is
# edited. Claude Code has no equivalent of Cursor's glob-scoped rule loading,
# so this mirrors it: full rule on the first qualifying edit per session,
# then a one-line reminder of the load-bearing rules on later edits — cheap
# insurance against context compaction without re-paying ~700 tokens per
# edit.

set -euo pipefail

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')

case "$file_path" in
  *.sql | *.yml) ;;
  *) exit 0 ;;
esac

dir=$(dirname "$file_path")
found=""
while [ -n "$dir" ] && [ "$dir" != "/" ]; do
  if [ -f "$dir/dbt_project.yml" ]; then
    found=1
    break
  fi
  dir=$(dirname "$dir")
done
[ -n "$found" ] || exit 0

emit() {
  jq -n --arg ctx "$1" \
    '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
}

session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')
marker=""
case "$session_id" in
  "" | *[!A-Za-z0-9_-]*) ;;
  *) marker="${TMPDIR:-/tmp}/claude-dbt-rules-${session_id}" ;;
esac

if [ -n "$marker" ] && [ -e "$marker" ]; then
  emit "Reminder — dbt conventions apply (full rules injected earlier this session): every model has a uniqueness test on its declared grain; a failing grain test is a finding, NEVER fixed by widening the key or deduplicating — stop and report the join that fanned out; all dedup (DISTINCT/QUALIFY/row_number) must be called for in the plan; marts carry a reconciliation test against a number the model does not control."
  exit 0
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
dbt_rule="$script_dir/../../cursor/rules/dbt.mdc"

if [ ! -f "$dbt_rule" ]; then
  echo "dbt-rules hook: missing dbt rule at $dbt_rule" >&2
  exit 1
fi

# Strip the YAML frontmatter (between the first two `---` lines).
rule_body=$(awk 'BEGIN{f=0} /^---$/{f++; next} f>=2{print}' "$dbt_rule")

prompt=$(
  cat <<PROMPT
You are editing files in a dbt project. The following conventions apply to
all dbt work this session:

<dbt_rules>
$rule_body
</dbt_rules>
PROMPT
)

if [ -n "$marker" ]; then
  touch "$marker"
fi
emit "$prompt"
