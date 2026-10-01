"""Shared helpers for reading Claude Code session transcripts.

Transcripts live at ~/.claude/projects/<project>/<session>.jsonl, one JSON object per line.
This module is imported by session_stats.py and plan_replay.py (same directory, so a plain
`import claude_transcripts` resolves under `uv run scripts/<name>.py`). It has no shebang and is
not run directly. Standard library only.

Two facts about the format that the helpers below account for:
  * Streaming writes the same assistant message on several lines (same `message.id`), so counts
    and token totals must be de-duplicated by id.
  * ExitPlanMode is rejected by the user as a tool error (`is_error`); plan mode is reviewed by
    rejecting and then replying, so a rejection is not by itself a sign of disagreement.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from pathlib import Path

DEFAULT_ROOT = Path.home() / ".claude" / "projects"
COMMAND_RE = re.compile(r"<command-name>/?([^<\s]+)</command-name>")
# Case-sensitive on purpose: the harness's own "Note: The user's next message..." must not match.
NOTE_RE = re.compile(r"^\s*(?:>\s*)?NOTE:\s*(.*)$")
READ_LINE_PREFIX_RE = re.compile(r"^\s*\d+\t")
FOLLOW_UP_WINDOW = 8  # user entries to scan after a plan result for the operator's next message

# Heuristic classes for the operator's message after a plan, first match wins. These are coarse
# by design: they exist to compare a plan-review change before/after, not to read minds.
LABEL_PATTERNS: list[tuple[str, re.Pattern[str]]] = [
    (
        "execute",
        re.compile(r"\b(execute|go ahead|go on|proceed|make the change|do it)\b", re.IGNORECASE),
    ),
    (
        "notes",
        re.compile(r"\b(left|added|wrote)\b.*\bnotes?\b|\bnotes? in the plan\b", re.IGNORECASE),
    ),
    (
        "assumptions",
        re.compile(
            r"assumption|unknown|spike|\bverify\b|check (any|the|those|these)|prior to launch",
            re.IGNORECASE,
        ),
    ),
    (
        "simplify",
        re.compile(
            r"streamline|high[- ]level|intuitive|split (the )?plan|drop the|simplif|shorter"
            r"|too long|easier to review|summar",
            re.IGNORECASE,
        ),
    ),
    (
        "context",
        re.compile(
            r"slack|jira|confluence|comments?\b|conflict|disconnect|original plan|merged",
            re.IGNORECASE,
        ),
    ),
    ("question", re.compile(r"\?")),
]


@dataclass
class PlanCall:
    session_id: str
    tool_use_id: str
    timestamp: str
    plan: str
    outcome: str = "pending"  # approved | rejected | pending
    next_message: str = ""
    next_command: str = ""
    label: str = "none"
    notes: list[str] = field(default_factory=list)  # operator `NOTE:` lines left in the plan file


def find_transcripts(root: Path = DEFAULT_ROOT) -> list[Path]:
    """Main-session transcripts only, oldest first; subagent ones live under a `subagents` dir.

    Oldest first matters: a forked or resumed session replays earlier history into a new file, so
    callers that de-duplicate across files keep the first (original) occurrence.
    """
    paths = (p for p in root.rglob("*.jsonl") if "subagents" not in p.parts)
    return sorted(paths, key=lambda p: (p.stat().st_mtime, p.name))


def read_entries(path: Path) -> list[dict]:
    entries: list[dict] = []
    with path.open(encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(obj, dict):
                entries.append(obj)
    return entries


def blocks(entry: dict) -> list[dict]:
    message = entry.get("message")
    content = message.get("content") if isinstance(message, dict) else None
    if isinstance(content, str):
        return [{"type": "text", "text": content}]
    if isinstance(content, list):
        return [b for b in content if isinstance(b, dict)]
    return []


def text_of(entry: dict) -> str:
    return "\n".join(b.get("text", "") for b in blocks(entry) if b.get("type") == "text").strip()


def classify(text: str) -> str:
    """Label the operator's reply to a plan; see LABEL_PATTERNS."""
    if not text:
        return "none"
    for label, pattern in LABEL_PATTERNS:
        if pattern.search(text):
            return label
    return "other"


def _follow_up(entries: list[dict], start: int) -> tuple[str, str]:
    """First real user message after `start`, plus the first slash command seen on the way.

    Skips tool results, local-command caveats and stdout, and interrupt markers, so the result is
    what the operator actually typed next.
    """
    command = ""
    seen = 0
    for entry in entries[start + 1 :]:
        if entry.get("type") != "user" or entry.get("isSidechain"):
            continue
        seen += 1
        if seen > FOLLOW_UP_WINDOW:
            break
        text = text_of(entry)
        if not text:
            continue
        match = COMMAND_RE.search(text)
        if match:
            command = command or match.group(1)
            continue
        if text.startswith(("<", "[Request interrupted")):
            continue
        return text, command
    return "", command


def _result_text(block: dict) -> str:
    content = block.get("content")
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "\n".join(b.get("text", "") for b in content if isinstance(b, dict))
    return ""


def _notes_after(entries: list[dict], start: int, plan: str) -> list[str]:
    """`NOTE:` lines the operator wrote into the plan file, recovered from the model's re-read.

    Notes are typed into the plan file in the editor (`/plan open`), so the transcript only holds
    them when the model reads that file back before the next ExitPlanMode. A note runs on over
    following lines that were not in the plan as presented, until a blank line or another note.
    """
    presented = {line.strip() for line in plan.splitlines()}
    notes: list[str] = []
    for entry in entries[start + 1 :]:
        if entry.get("isSidechain"):
            continue
        entry_blocks = blocks(entry)
        if entry.get("type") == "assistant" and any(
            b.get("type") == "tool_use" and b.get("name") == "ExitPlanMode" for b in entry_blocks
        ):
            break
        for block in entry_blocks:
            if block.get("type") != "tool_result":
                continue
            lines = [READ_LINE_PREFIX_RE.sub("", ln) for ln in _result_text(block).splitlines()]
            for i, line in enumerate(lines):
                match = NOTE_RE.match(line)
                if not match or line.strip() in presented:
                    continue
                parts = [match.group(1).strip()]
                for follow in lines[i + 1 :]:
                    stripped = follow.strip()
                    if not stripped or stripped in presented or NOTE_RE.match(follow):
                        break
                    parts.append(stripped)
                note = " ".join(p for p in parts if p)
                if note and note not in notes:
                    notes.append(note)
    return notes


def _has_tool_use(entry: dict, tool_use_id: str) -> bool:
    return entry.get("type") == "assistant" and any(
        b.get("type") == "tool_use" and b.get("id") == tool_use_id for b in blocks(entry)
    )


def plan_calls(entries: list[dict]) -> list[PlanCall]:
    """One PlanCall per unique ExitPlanMode tool_use id, with outcome and the operator's reply."""
    calls: dict[str, PlanCall] = {}
    results: dict[str, tuple[int, bool]] = {}
    for index, entry in enumerate(entries):
        if entry.get("isSidechain"):
            continue
        for block in blocks(entry):
            kind = block.get("type")
            if (
                entry.get("type") == "assistant"
                and kind == "tool_use"
                and block.get("name") == "ExitPlanMode"
                and block.get("id")
            ):
                plan = (block.get("input") or {}).get("plan") or ""
                existing = calls.get(block["id"])
                if existing is None:
                    calls[block["id"]] = PlanCall(
                        entry.get("sessionId", ""), block["id"], entry.get("timestamp", ""), plan
                    )
                elif len(plan) > len(existing.plan):
                    existing.plan = plan  # streaming can repeat the call with a partial input
            elif entry.get("type") == "user" and kind == "tool_result" and block.get("tool_use_id"):
                results.setdefault(block["tool_use_id"], (index, block.get("is_error") is True))
    for tool_use_id, call in calls.items():
        if tool_use_id not in results:
            continue
        index, is_error = results[tool_use_id]
        call.outcome = "rejected" if is_error else "approved"
        call.next_message, call.next_command = _follow_up(entries, index)
        call.label = classify(call.next_message)
        if is_error:
            call_index = next(i for i, e in enumerate(entries) if _has_tool_use(e, tool_use_id))
            call.notes = _notes_after(entries, call_index, call.plan)
            if call.notes:
                call.label = "notes"  # the notes are the reply; "left notes" is just the pointer
        elif call.label in ("none", "other"):
            call.label = "execute"  # approved with no objection: the plan was executed as-is
    return sorted(calls.values(), key=lambda c: c.timestamp)


def unique_plan_calls(root: Path = DEFAULT_ROOT) -> list[PlanCall]:
    """Every plan across all transcripts, each `tool_use_id` once (oldest file wins)."""
    seen: set[str] = set()
    plans: list[PlanCall] = []
    for path in find_transcripts(root):
        for call in plan_calls(read_entries(path)):
            if call.tool_use_id not in seen:
                seen.add(call.tool_use_id)
                plans.append(call)
    return sorted(plans, key=lambda c: c.timestamp)
