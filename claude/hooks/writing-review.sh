#!/usr/bin/env bash
# PreToolUse(Bash) hook: review prose before it becomes permanent.
#
# Gates `git commit`, `gh pr create` and `gh pr edit --body`, and asks a
# *separate* `claude -p` process whether the prose breaks the readability rule
# (cursor/rules/writing.mdc). If it does, the command is denied and the
# reviewer's rewrites come back as the reason.
#
# Scope is the prose body only. Docstring form -- imperative summary, no
# signature restatement, blank line after the summary -- is PEP 257's, settled
# since 2001 and enforced mechanically by ruff's D401/D402/D404/D205. The rule
# and the prompt both say to leave those alone.
#
# Why a separate process rather than asking the writing session to check its
# own work: models correct errors handed to them as external input and miss
# the same errors in their own output ("Self-correction is Not An Innate
# Capability in Language Models", arXiv 2410.20513; "Cross-Context Review",
# arXiv 2603.12123). The existing in-session critique hooks cannot catch this
# class of problem, which is what prompted this one.
#
# The reviewer is asked a comparative question -- does a rewrite read better,
# and which rule does the original break -- rather than for a score. Pairwise
# judgement tracks human agreement better than absolute scoring on subjective
# qualities like conciseness.
#
# Robustness invariants (a prose gate must never stop someone committing):
#   - Every error path exits 0 and allows the command: no `claude` on PATH,
#     a timeout, malformed JSON, an unreadable rule file, no staged changes.
#   - Blocks at most twice for the same prose, tracked by hash in a
#     per-session file. The third attempt passes. Same reasoning as
#     stop-check.sh: re-checking is how agents get stuck in loops.
#   - CLAUDE_WRITING_REVIEW guards against recursion. The reviewer inherits
#     this settings.json, so without it a review could trigger a review.

set -uo pipefail # no -e: error paths must fall through to allowing the command

# --- recursion guard: the reviewer subprocess must not re-enter this hook ---
[ -n "${CLAUDE_WRITING_REVIEW:-}" ] && exit 0

input=$(cat) || exit 0
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null) || exit 0
[ "$tool" = "Bash" ] || exit 0

cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0

# --- gate: only the three commands that publish prose ---
case "$cmd" in
  *"git commit"*) ;;
  *"gh pr create"*) ;;
  *"gh pr edit"*) ;;
  *) exit 0 ;;
esac

# `--amend --no-edit` reuses an existing message; there is nothing new to read.
case "$cmd" in
  *--no-edit*) exit 0 ;;
esac

command -v claude >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd) || exit 0
rule_file="$script_dir/../../cursor/rules/writing.mdc"
[ -f "$rule_file" ] || exit 0

# Strip YAML frontmatter and the checks manifest, leaving the rule to inject.
rule_body=$(awk '
  BEGIN{f=0}
  /^---$/{f++; next}
  f<2{next}
  /^<!-- checks$/{s=1; next}
  /^-->$/{if(s){s=0; next}}
  !s{print}
' "$rule_file" 2>/dev/null) || exit 0
[ -n "$rule_body" ] || exit 0

# --- collect the prose this command would publish ---

# The message or body as written in the command itself. Heredocs, -m and
# --body all end up in the command string, so take the whole thing minus the
# shell scaffolding rather than parsing each form separately.
from_command=$(printf '%s' "$cmd" \
  | grep -vE '^\s*(git|gh|cd|EOF|<<|\)|\}|fi|done)' \
  | grep -vE '^\s*(Co-Authored-By|Claude-Session|https://|🤖)' \
  | sed -e 's/^[[:space:]]*//' 2>/dev/null) || from_command=""

# Added prose from the staged diff: every added line in a .md file, and added
# lines inside triple-quoted blocks in .py files. Docstrings are the reason
# this hook exists and they never appear in the command string.
staged=""
if printf '%s' "$cmd" | grep -q "git commit"; then
  staged=$(git diff --cached -U0 2>/dev/null | awk '
    /^\+\+\+ b\//{ file=$2; sub(/^b\//,"",file); inpy=(file ~ /\.py$/); md=(file ~ /\.md$/); q=0; next }
    /^\+/ {
      line=substr($0,2)
      if (md) { print line; next }
      if (!inpy) next
      n=gsub(/"""/,"\"\"\"",line)
      if (q) { print line }
      else if (n>0) { print line }
      if (n%2==1) q=!q
    }
  ' 2>/dev/null) || staged=""
fi

prose=$(printf '%s\n%s\n' "$from_command" "$staged")
words=$(printf '%s' "$prose" | wc -w | tr -d ' ')

# Under ~40 words there is nothing worth a network round trip.
[ "${words:-0}" -lt 40 ] && exit 0

# --- block cap: at most twice for the same prose ---
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null) || session_id=""
state_file=""
case "$session_id" in
  '' | *[!A-Za-z0-9_-]*) ;;
  *) state_file="${TMPDIR:-/tmp}/claude-writing-${session_id}" ;;
esac

prose_hash=$(printf '%s' "$prose" | cksum 2>/dev/null | cut -d' ' -f1) || prose_hash=""
if [ -n "$state_file" ] && [ -n "$prose_hash" ] && [ -f "$state_file" ]; then
  seen=$(grep -c "^${prose_hash}$" "$state_file" 2>/dev/null) || seen=0
  [ "${seen:-0}" -ge 2 ] && exit 0
fi

# --- ask a fresh model ---
# The prompt lives in writing-review.md rather than in a heredoc here.
# A heredoc nested inside $( ) is still parsed for quotes, so one apostrophe
# in the prompt text is a syntax error -- one that shellcheck does not report
# and only `bash -n` catches. Keeping the prompt in a file removes that whole
# class of breakage, and makes the prompt reviewable on its own. It is `.md`
# so `make fmt_check` covers it; the JSON examples are fenced because mdformat
# would otherwise wrap and escape them.
prompt_file="$script_dir/writing-review.md"
[ -f "$prompt_file" ] || exit 0
prompt_template=$(cat "$prompt_file" 2>/dev/null) || exit 0
[ -n "$prompt_template" ] || exit 0

prompt=${prompt_template//__RULE__/$rule_body}
prompt=${prompt//__PROSE__/$prose}

verdict=$(CLAUDE_WRITING_REVIEW=1 printf '%s' "$prompt" \
  | CLAUDE_WRITING_REVIEW=1 claude -p --model sonnet 2>/dev/null) || exit 0
[ -n "$verdict" ] || exit 0

# Tolerate a fenced or chatty reply: take the outermost {...}. Written with
# grep rather than a sed that strips markdown fences, because a literal
# fence in the source is three backticks, and backticks inside $( ) break
# the parse in a way shellcheck does not report.
verdict=$(printf '%s' "$verdict" | tr '\n' ' ' | grep -o '{.*}' | head -1) || exit 0

count=$(printf '%s' "$verdict" | jq -r '.blocks | length' 2>/dev/null) || exit 0
case "$count" in
  '' | *[!0-9]*) exit 0 ;;
  0) exit 0 ;;
esac

reason=$(
  echo "A separate reviewer found prose here that breaks the writing rule"
  echo "(cursor/rules/writing.mdc). Apply these, then re-run the command."
  echo
  printf '%s' "$verdict" | jq -r '.blocks[] |
    "── \(.rule)\n\n  now: \(.original)\n\n  try: \(.rewrite)\n"' 2>/dev/null
  echo
  echo "Rewrite the text itself; do not argue the verdict back. If a rewrite"
  echo "loses a fact, keep the fact and reword around it."
) || exit 0

[ -n "$state_file" ] && [ -n "$prose_hash" ] &&
  printf '%s\n' "$prose_hash" >>"$state_file" 2>/dev/null

jq -n --arg reason "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason
  }
}' 2>/dev/null || true

exit 0
