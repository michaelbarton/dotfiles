#!/usr/bin/env bash
# Stop hook: force one skeptical critique pass on a long plan (>150 lines).
# Reads the plan path from a pointer file written by plan-review.sh
# (PostToolUse on plan edits). Blocks once per plan path per session via a
# marker file; fails open on every error path.
#
# What this does NOT do: Stop fires after the assistant's message has already
# streamed, so the operator does see the first draft. What the block buys is
# that the turn does not end there — the agent revises and hands back a
# corrected plan without the operator having to leave notes.
#
# Also registered on PostToolUse(ExitPlanMode), where it does the opposite:
# once a plan has been presented for approval, it retires the critique for
# that plan by setting the marker. Blocking after the operator has already
# acted on the plan is pure waste.
#
# Robustness invariants (reviewer, not a security gate):
#   - Blocks at most ONCE per plan path per session: when stop_hook_active
#     is set (Claude is already continuing because of this hook), allow
#     unconditionally. We deliberately do not re-check whether the plan
#     improved — re-checking is how agents get stuck in loops.
#   - Plans <=150 lines are never blocked.
#   - Every error path fails open (exit 0, no block).

set -uo pipefail # no -e: error paths must fall through to allow the stop

input=$(cat) || exit 0
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null) || exit 0
[ -z "$session_id" ] && exit 0
case "$session_id" in
  *[!A-Za-z0-9_-]*) exit 0 ;;
esac

pointer_file="${TMPDIR:-/tmp}/claude-plan-${session_id}"
[ -f "$pointer_file" ] || exit 0
plan_path=$(cat "$pointer_file" 2>/dev/null) || exit 0
[ -f "$plan_path" ] || exit 0

path_hash=$(printf '%s' "$plan_path" | shasum -a 1 2>/dev/null | awk '{print $1}') || exit 0
[ -n "$path_hash" ] || exit 0
marker_file="${TMPDIR:-/tmp}/claude-plan-critique-${session_id}-${path_hash}"

# Dispatch on the tool name rather than hook_event_name: a Stop payload has no
# .tool_name at all, so the empty case is unambiguously the Stop path and an
# unexpected tool event can neither block nor retire a critique.
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null) || tool_name=""
case "$tool_name" in
  # The plan has been handed to the operator for approval; critiquing it now is
  # waste. Retire it so the next Stop does not fire.
  ExitPlanMode)
    touch "$marker_file" 2>/dev/null || true
    exit 0
    ;;
  "") ;;      # Stop event — fall through to the critique
  *) exit 0 ;; # any other tool event — not ours
esac

stop_hook_active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null) || stop_hook_active=false
if [ "$stop_hook_active" = "true" ]; then
  exit 0
fi

# `wc -l <file` pads with spaces on macOS; trim so it interpolates cleanly.
line_count=$(wc -l <"$plan_path" 2>/dev/null | tr -d '[:space:]') || exit 0
[ -n "$line_count" ] || exit 0
[ "$line_count" -gt 150 ] 2>/dev/null || exit 0

[ -f "$marker_file" ] && exit 0

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
critique_rule="$script_dir/../../cursor/rules/plan-critique.mdc"

if [ ! -f "$critique_rule" ]; then
  echo "plan-critique hook: missing critique rule at $critique_rule" >&2
  exit 1
fi

gates=$(awk '/^<!-- critique$/{f=1; next} /^-->$/{f=0} f' "$critique_rule")
if [ -z "$gates" ]; then
  echo "plan-critique hook: no critique manifest (<!-- critique ... -->) in $critique_rule" >&2
  exit 1
fi

rule_body=$(awk '
  BEGIN{f=0}
  /^---$/{f++; next}
  f<2{next}
  /^<!-- critique$/{s=1; next}
  /^-->$/{if(s){s=0; next}}
  !s{print}
' "$critique_rule")

# Case-insensitive: sentence-initial hedges ("Probably …", "Unclear whether …")
# are the common form in prose and a case-sensitive match misses all of them.
hedge_hits=$(grep -niE 'probably|presumably|likely|should be|I (believe|think)|appears to|seems to|might be|may be|unclear|not sure' \
  "$plan_path" 2>/dev/null) || hedge_hits=""

reason=$(
  cat <<PROMPT
Before presenting this plan to the operator, critique it against the rubric
in <plan_critique_rule> below. The gates are:

$gates

Plan: $plan_path ($line_count lines)

A gate passes ONLY if you can quote the plan line(s) that satisfy it.
Paraphrases, "implied somewhere," or "this is obvious" do NOT count.
If you are unsure whether a quote satisfies a gate, the gate FAILS.

<plan_critique_rule>
$rule_body
</plan_critique_rule>
PROMPT
)

if [ -n "$hedge_hits" ]; then
  reason="${reason}

## Hedge-language candidates (gate 4 — Verified, not asserted)

Each line below is a candidate for gate 4. For each, either cite the source
that verifies the claim or rewrite with UNVERIFIED: prefix.

$hedge_hits"
fi

reason="${reason}

## Critique output

Output exactly one line per gate, in the order listed above:

\`<gate>: PASS — \"<quoted plan line>\"\`
\`<gate>: FAIL — <specific gap>\`
\`<gate>: N/A — <why this gate does not apply>\`

Apply the fixes and continue."

touch "$marker_file" 2>/dev/null || exit 0

jq -n --arg reason "$reason" '{decision: "block", reason: $reason}' 2>/dev/null || true
exit 0
