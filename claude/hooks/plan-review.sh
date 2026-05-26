#!/usr/bin/env bash
# PostToolUse(Write|Edit) hook: review plan documents.
# Path-gates first so non-plan edits exit silently, then prints an audit
# prompt that wraps the canonical planning rule (cursor/rules/planning.mdc).

set -euo pipefail

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')

case "$file_path" in
  */.cursor/plans/*|*/.claude/plans/*) ;;
  *) exit 0 ;;
esac

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
planning_rule="$script_dir/../../cursor/rules/planning.mdc"

if [ ! -f "$planning_rule" ]; then
  echo "plan-review hook: missing planning rule at $planning_rule" >&2
  exit 1
fi

cat <<'PREAMBLE'
You just edited a plan document. Before any implementation, audit it
against the planning rule below (the canonical gate definitions). Be
strict: a gate passes ONLY if you can quote the line(s) that satisfy it.
Paraphrases, "implied somewhere," or "this is obvious" do NOT count.

---
PREAMBLE

# Strip the YAML frontmatter (between the first two `---` lines).
awk 'BEGIN{f=0} /^---$/{f++; next} f>=2{print}' "$planning_rule"

cat <<'POSTAMBLE'
---

## Audit output

If every applicable gate passes: output exactly `PLAN OK` on a single
line and nothing else.

Otherwise: output a bulleted gap list. Each bullet:
`Gate <name>: <specific gap>`. Then stop and ask the user to fill the
gaps before implementing.
POSTAMBLE
