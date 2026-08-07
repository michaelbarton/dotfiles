#!/usr/bin/env bash
# PostToolUse(Write|Edit) hook: review plan documents.
# Path-gates first so non-plan edits exit silently, then emits an audit
# prompt wrapping the canonical planning rule (cursor/rules/planning.mdc)
# as PostToolUse additionalContext JSON — plain stdout at exit 0 never
# reaches the model. The full rule (~300 tokens) is injected on every
# plan edit: a once-per-session marker would go stale after context
# compaction, leaving the model auditing against a rubric it no longer
# has.

set -euo pipefail

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')

case "$file_path" in
  */.cursor/plans/* | */.claude/plans/*) ;;
  *) exit 0 ;;
esac

session_id=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null) || true
case "$session_id" in
  '' | *[!A-Za-z0-9_-]*) ;;
  *) printf '%s' "$file_path" > "${TMPDIR:-/tmp}/claude-plan-${session_id}" 2>/dev/null || true ;;
esac

emit() {
  jq -n --arg ctx "$1" \
    '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
planning_rule="$script_dir/../../cursor/rules/planning.mdc"

if [ ! -f "$planning_rule" ]; then
  echo "plan-review hook: missing planning rule at $planning_rule" >&2
  exit 1
fi

# The gate list is the single source of truth: it lives in the rule as a
# `<!-- gates ... -->` comment (invisible in Cursor's rendered view) and is
# extracted here rather than duplicated, so the two can never drift.
gates=$(awk '/^<!-- gates$/{f=1; next} /^-->$/{f=0} f' "$planning_rule")
if [ -z "$gates" ]; then
  echo "plan-review hook: no gate manifest (<!-- gates ... -->) in $planning_rule" >&2
  exit 1
fi

# Strip the YAML frontmatter (between the first two `---` lines) and the gate
# manifest comment, leaving the human-readable rule to inject verbatim.
rule_body=$(awk '
  BEGIN{f=0}
  /^---$/{f++; next}
  f<2{next}
  /^<!-- gates$/{s=1; next}
  /^-->$/{if(s){s=0; next}}
  !s{print}
' "$planning_rule")

prompt=$(
  cat <<PROMPT
You just edited a plan document. Before any implementation, audit it
against the planning rule in <planning_rule> below. The gates are:

$gates

A gate passes ONLY if you can quote the plan line(s) that satisfy it.
Paraphrases, "implied somewhere," or "this is obvious" do NOT count.
If you are unsure whether a quote satisfies a gate, the gate FAILS.

<planning_rule>
$rule_body
</planning_rule>

## Audit output

Output exactly one line per gate, in the order listed above:

\`<gate>: PASS — "<quoted plan line>"\`
\`<gate>: FAIL — <specific gap>\`
\`<gate>: N/A — <why this gate does not apply>\`

If there are no FAIL lines, end with \`PLAN OK\` on its own line and
begin implementing. Otherwise close the gaps yourself by reading the code;
surface only genuine decisions (trade-offs, scope, operator judgement),
naming the gate each came from.
PROMPT
)

emit "$prompt"
