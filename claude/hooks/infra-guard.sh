#!/usr/bin/env bash
# PreToolUse(Bash) hook: gate commands that submit real, billable compute jobs
# or push container images, before they run.
#
# This script is intentionally generic and contains no employer-specific
# names, IDs, or vocabulary -- the actual rules (which command shapes to
# gate, and which words escalate a match to a hard block) live in an external
# JSON file, read from $INFRA_GUARD_RULES or, by default,
# ~/.local/claude/infra-guard-rules.json. With no rules file present this
# hook is a complete no-op (every command passes straight through), so it is
# safe to ship in a public dotfiles repo unconditionally.
#
# Rules file schema:
#   {
#     "deny_words": ["example-env-name", ...],
#     "rules": [
#       {"name": "...", "all_of": ["substr", ...], "any_of": ["substr", ...]}
#     ]
#   }
# A rule matches a command when every string in "all_of" is a literal
# substring of it, and (if "any_of" is given) at least one string in "any_of"
# is too. "any_of" is optional.
#
# On a match:
#   - if the command also contains one of "deny_words" as a whole word, the
#     command is denied outright, no confirmation offered.
#   - otherwise, a `claude -p` call summarizes in one plain sentence what the
#     command will do, and the command is held for interactive confirmation
#     ("ask") with that summary as the reason.
#
# Fail-safe direction (deliberately asymmetric, see the dotfiles PR that
# added this file for the reasoning): a missing or malformed rules file, or a
# missing `jq`, fails toward *allow* -- that means no policy is configured,
# not that a dangerous command is being hidden. But once a rule has matched,
# every subsequent failure (the `claude -p` summarization call erroring,
# timing out, or returning nothing usable) must still fail toward *ask*,
# never silently toward allow -- the entire point of this hook is gating an
# action class that must not slip through unnoticed.

set -uo pipefail # no -e: error paths must fall through to the correct fail-safe branch

# --- recursion guard: the summarizer subprocess must not re-enter this hook ---
[ -n "${CLAUDE_INFRA_GUARD:-}" ] && exit 0

input=$(cat) || exit 0
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null) || exit 0
[ "$tool" = "Bash" ] || exit 0

cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0

command -v jq >/dev/null 2>&1 || exit 0

rules_file="${INFRA_GUARD_RULES:-$HOME/.local/claude/infra-guard-rules.json}"
[ -f "$rules_file" ] || exit 0
jq -e . "$rules_file" >/dev/null 2>&1 || exit 0

# --- find the first rule (if any) this command matches ---
rule_count=$(jq -r '(.rules // []) | length' "$rules_file" 2>/dev/null) || exit 0
case "$rule_count" in '' | *[!0-9]*) exit 0 ;; esac

matched_name=""
i=0
while [ "$i" -lt "$rule_count" ]; do
  rule=$(jq -c ".rules[$i]" "$rules_file" 2>/dev/null) || rule=""
  i=$((i + 1))
  [ -n "$rule" ] && [ "$rule" != "null" ] || continue

  name=$(printf '%s' "$rule" | jq -r '.name // empty' 2>/dev/null)
  [ -n "$name" ] || continue

  all_ok=1
  while IFS= read -r substr; do
    [ -n "$substr" ] || continue
    case "$cmd" in
    *"$substr"*) ;;
    *)
      all_ok=0
      break
      ;;
    esac
  done < <(printf '%s' "$rule" | jq -r '.all_of[]? // empty' 2>/dev/null)
  [ "$all_ok" = "1" ] || continue

  any_of=$(printf '%s' "$rule" | jq -r '.any_of[]? // empty' 2>/dev/null)
  if [ -n "$any_of" ]; then
    any_ok=0
    while IFS= read -r substr; do
      [ -n "$substr" ] || continue
      case "$cmd" in
      *"$substr"*) any_ok=1 ;;
      esac
    done <<<"$any_of"
    [ "$any_ok" = "1" ] || continue
  fi

  matched_name="$name"
  break
done

[ -n "$matched_name" ] || exit 0

# --- a rule matched: check for a deny-word escalation ---
deny_hit=""
while IFS= read -r word; do
  [ -n "$word" ] || continue
  pattern="(^|[^A-Za-z0-9_])(${word})([^A-Za-z0-9_]|\$)"
  if printf '%s' "$cmd" | grep -Eq "$pattern" 2>/dev/null; then
    deny_hit="$word"
    break
  fi
done < <(jq -r '.deny_words[]? // empty' "$rules_file" 2>/dev/null)

if [ -n "$deny_hit" ]; then
  reason="BLOCKED: matches guarded pattern '${matched_name}' and contains '${deny_hit}', which ${rules_file} treats as always-deny. No confirmation is offered for this combination. Command: ${cmd}"
  jq -n --arg reason "$reason" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }' 2>/dev/null
  exit 0
fi

# --- ask tier: summarize the command in one plain sentence ---
reason=""
if command -v claude >/dev/null 2>&1; then
  prompt=$(printf 'In one plain English sentence (no jargon, do not restate the command verbatim), say exactly what this shell command will do to real infrastructure, naming the specific resource (queue, image, cluster, bucket, etc.) it targets:\n\n%s\n' "$cmd")
  reason=$(CLAUDE_INFRA_GUARD=1 printf '%s' "$prompt" \
    | CLAUDE_INFRA_GUARD=1 claude -p --model sonnet 2>/dev/null) || reason=""
  reason=$(printf '%s' "$reason" | tr '\n' ' ' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
fi

if [ -z "$reason" ]; then
  reason="Matches guarded pattern '${matched_name}' (see ${rules_file}). Command: ${cmd}"
fi

jq -n --arg reason "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "ask",
    permissionDecisionReason: $reason
  }
}' 2>/dev/null

exit 0
