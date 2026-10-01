#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""PreToolUse(Bash) hook: gate commands that submit real, billable compute jobs or push
container images, before they run.

This script is intentionally generic and contains no employer-specific names, IDs, or
vocabulary -- the actual rules live in an external JSON file, read from $INFRA_GUARD_RULES
or, by default, ~/.local/claude/infra-guard-rules.json. With no rules file present this hook
is a complete no-op, so it is safe to ship in a public dotfiles repo unconditionally.

Rules file schema:

    {
      "deny_words": ["example-env-name", ...],
      "rules": [{"name": "...", "all_of": ["substr", ...], "any_of": ["substr", ...]}]
    }

A rule matches a command when every string in "all_of" is a literal substring of it and, if
"any_of" is given and non-empty, at least one string in "any_of" is too.

On a match:
  - if the command also contains a deny word (as a whole word), it is denied outright;
  - otherwise a `claude -p` call summarizes the command's consequence in one sentence, and
    the command is held for interactive confirmation ("ask") with that summary as the reason.

Fail-safe direction is deliberately asymmetric. Before a rule matches, any problem (no rules
file, malformed rules, unexpected input) fails toward *allow*: no policy is configured, which
is not the same as a dangerous command being hidden. After a rule matches, every failure
(summarizer erroring, timing out, returning nothing) still fails toward *ask*.
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path

RULES_FILE = Path(os.environ.get("INFRA_GUARD_RULES", "~/.local/claude/infra-guard-rules.json"))
SUMMARY_TIMEOUT_S = 25  # the hook itself is allowed 30s in settings.json
SUMMARY_PROMPT = (
    "In one plain English sentence (no jargon, do not restate the command verbatim), say "
    "exactly what this shell command will do to real infrastructure, naming the specific "
    "resource (queue, image, cluster, bucket, etc.) it targets:\n\n{cmd}\n"
)


def respond(decision: str, reason: str) -> None:
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": decision,
                    "permissionDecisionReason": reason,
                }
            }
        )
    )


def load_rules(path: Path) -> dict:
    """Return the parsed rules, or an empty policy if the file is missing or malformed."""
    try:
        rules = json.loads(path.expanduser().read_text())
    except (OSError, ValueError):
        return {}
    return rules if isinstance(rules, dict) else {}


def matching_rule(cmd: str, rules: list) -> str | None:
    """Name of the first rule whose substring conditions the command satisfies."""
    for rule in rules:
        if not isinstance(rule, dict) or not rule.get("name"):
            continue
        all_of = [s for s in rule.get("all_of") or [] if s]
        any_of = [s for s in rule.get("any_of") or [] if s]
        if all(s in cmd for s in all_of) and (not any_of or any(s in cmd for s in any_of)):
            return rule["name"]
    return None


def deny_word_in(cmd: str, words: list) -> str | None:
    for word in filter(None, words):
        if re.search(rf"(?<![A-Za-z0-9_]){re.escape(word)}(?![A-Za-z0-9_])", cmd):
            return word
    return None


def summarize(cmd: str) -> str:
    """One-sentence consequence of `cmd` from `claude -p`, or "" on any failure."""
    try:
        result = subprocess.run(
            ["claude", "-p", "--model", "sonnet"],
            input=SUMMARY_PROMPT.format(cmd=cmd),
            env={**os.environ, "CLAUDE_INFRA_GUARD": "1"},  # keep the child out of this hook
            capture_output=True,
            text=True,
            timeout=SUMMARY_TIMEOUT_S,
            check=True,
        )
    except (OSError, subprocess.SubprocessError):
        return ""
    return " ".join(result.stdout.split())


def main() -> None:
    if os.environ.get("CLAUDE_INFRA_GUARD"):
        return  # recursion guard: the summarizer subprocess must not re-enter this hook

    try:
        event = json.load(sys.stdin)
        cmd = event["tool_input"]["command"] if event["tool_name"] == "Bash" else ""
    except (ValueError, KeyError, TypeError):
        return
    if not cmd or not isinstance(cmd, str):
        return

    policy = load_rules(RULES_FILE)
    rules = policy.get("rules")
    name = matching_rule(cmd, rules) if isinstance(rules, list) else None
    if name is None:
        return

    deny_words = policy.get("deny_words")
    if isinstance(deny_words, list) and (word := deny_word_in(cmd, deny_words)):
        respond(
            "deny",
            f"BLOCKED: matches guarded pattern '{name}' and contains '{word}', which "
            f"{RULES_FILE} treats as always-deny. No confirmation is offered for this "
            f"combination. Command: {cmd}",
        )
        return

    respond(
        "ask",
        summarize(cmd) or f"Matches guarded pattern '{name}' (see {RULES_FILE}). Command: {cmd}",
    )


if __name__ == "__main__":
    main()
