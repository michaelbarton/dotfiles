#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["pytest"]
# ///
"""Tests for infra-guard.py. Run directly: claude/hooks/test_infra_guard.py"""

import importlib.util
import json
import sys
from pathlib import Path

import pytest

_spec = importlib.util.spec_from_file_location(
    "infra_guard", Path(__file__).with_name("infra-guard.py")
)
guard = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(guard)

RULES = [
    {"name": "push", "all_of": ["docker", "push"]},
    {"name": "batch", "all_of": ["aws", "batch", "submit-job"]},
    {"name": "nf", "all_of": ["nextflow run"], "any_of": ["-profile remote", "-profile aws"]},
]


def matches(cmd: str) -> str | None:
    return guard.matching_rule(guard.tokenize(cmd), RULES)


@pytest.mark.parametrize(
    "cmd",
    [
        "docker push img",
        "docker login x && docker push img",
        "cd d; docker push img",
        "FOO=1 docker push img",
        "docker  push img",  # repeated whitespace
        "docker --debug push img",  # inserted flag
        "docker image push img",
        "aws --profile p batch submit-job --job-queue q",
        'aws batch "submit-job" --job-queue q',  # quoted word
        "nextflow run main.nf -profile remote",
        "nextflow run main.nf -profile=remote",
        'nextflow run main.nf -profile "remote"',
        "nextflow run main.nf   -profile   remote -bg",
        "bash -c 'docker push img'",
        'echo "$(docker push img)"',
        "echo `docker push img`",
        "docker push 'unterminated",  # shlex fails; falls back to bare words
    ],
)
def test_caught(cmd):
    assert matches(cmd)


@pytest.mark.parametrize(
    "cmd",
    [
        "ls -la",
        "nextflow run main.nf -profile test",
        "nextflow config -profile remote",
        "docker login x",
        "aws batch describe-jobs --jobs j",
        'git commit -m "never run docker push by hand"',
        'grep -r "docker push" docs/',
        "docker pushover",  # token match, not substring
    ],
)
def test_not_caught(cmd):
    assert matches(cmd) is None


def test_deny_word_boundaries():
    words = ["prod"]
    assert guard.deny_word_in("docker push x-prod", words)
    assert guard.deny_word_in("--job-queue prod_queue", words)
    assert guard.deny_word_in("img:PROD-1", words)
    assert not guard.deny_word_in("docker push product", words)
    assert not guard.deny_word_in("docker push myprod", words)


@pytest.mark.parametrize(
    "policy",
    [
        [],
        {"rules": "x"},
        {"rules": [{"name": "a"}]},  # no conditions: would match everything
        {"rules": [{"name": "a", "all_of": []}]},
        {"rules": [{"name": "a", "all_of": "docker push"}]},  # str, not list
        {"rules": [{"name": "a", "all_of": [""]}]},
        {"rules": [{"all_of": ["x"]}]},  # no name
        {"rules": [{"name": "a", "all_of": ["x"]}], "deny_words": [""]},
        {"rules": [{"name": "a", "all_of": ["x"]}], "deny_words": "prod"},
    ],
)
def test_invalid_policy_rejected(policy):
    with pytest.raises(guard.InvalidRules):
        guard.validate(policy)


def test_valid_policy_accepted():
    rules, words = guard.validate({"rules": RULES, "deny_words": ["prod"]})
    assert rules == RULES and words == ["prod"]


def run_hook(monkeypatch, capsys, tmp_path, cmd, rules_text=None, summary="Pushes an image."):
    rules_file = tmp_path / "rules.json"
    if rules_text is not None:
        rules_file.write_text(rules_text)
    monkeypatch.setattr(guard, "RULES_FILE", rules_file)
    monkeypatch.setattr(guard, "summarize", lambda cmd: summary)
    monkeypatch.delenv("CLAUDE_INFRA_GUARD", raising=False)
    event = {"tool_name": "Bash", "tool_input": {"command": cmd}}
    monkeypatch.setattr(sys, "stdin", __import__("io").StringIO(json.dumps(event)))
    guard.main()
    out = capsys.readouterr().out
    return json.loads(out)["hookSpecificOutput"] if out else None


POLICY = json.dumps({"rules": RULES, "deny_words": ["prod"]})


def test_no_rules_file_is_noop(monkeypatch, capsys, tmp_path):
    assert run_hook(monkeypatch, capsys, tmp_path, "docker push x-prod") is None


def test_broken_rules_file_asks_for_everything(monkeypatch, capsys, tmp_path):
    out = run_hook(monkeypatch, capsys, tmp_path, "ls", rules_text="{not json")
    assert out["permissionDecision"] == "ask" and "cannot read" in out["permissionDecisionReason"]


def test_ask_shows_summary_and_raw_command(monkeypatch, capsys, tmp_path):
    out = run_hook(monkeypatch, capsys, tmp_path, "docker push img", POLICY, "Pushes an image.")
    assert out["permissionDecision"] == "ask"
    assert out["permissionDecisionReason"].startswith("Pushes an image.")
    assert "Command: docker push img" in out["permissionDecisionReason"]


def test_summarizer_failure_still_asks(monkeypatch, capsys, tmp_path):
    out = run_hook(monkeypatch, capsys, tmp_path, "docker push img", POLICY, summary="")
    assert out["permissionDecision"] == "ask" and "push" in out["permissionDecisionReason"]


def test_deny_word_denies(monkeypatch, capsys, tmp_path):
    out = run_hook(monkeypatch, capsys, tmp_path, "docker push img:prod", POLICY)
    assert out["permissionDecision"] == "deny"


def test_unmatched_command_passes_silently(monkeypatch, capsys, tmp_path):
    assert run_hook(monkeypatch, capsys, tmp_path, "ls", POLICY) is None


def test_recursion_guard(monkeypatch, capsys, tmp_path):
    monkeypatch.setenv("CLAUDE_INFRA_GUARD", "1")
    monkeypatch.setattr(guard, "RULES_FILE", tmp_path / "missing.json")
    guard.main()
    assert capsys.readouterr().out == ""


def test_crash_in_guard_asks_not_allows(monkeypatch, capsys, tmp_path):
    monkeypatch.setattr(guard, "matching_rule", lambda *a: 1 / 0)
    out = run_hook(monkeypatch, capsys, tmp_path, "docker push img", POLICY)
    assert out["permissionDecision"] == "ask" and "crashed" in out["permissionDecisionReason"]


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-q", *sys.argv[1:]]))
