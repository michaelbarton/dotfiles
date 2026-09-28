#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""Usage and plan-review statistics from Claude Code session transcripts.

Run before and after a config change (model, effort, hooks, CLAUDE.md, planning rubric) and
compare, instead of judging by feel. Reads ~/.claude/projects/**/*.jsonl; never writes to it.

Grain of each table:
  usage  - one row per unique assistant message (`message.id`), rolled up per session and model
  plans  - one row per unique ExitPlanMode `tool_use_id`

Subagent transcripts and sidechain messages are excluded, so token totals cover the main
conversation only. A plan "rejection" is how plan mode is normally reviewed (reject, read the
plan, reply), so look at the follow-up labels rather than the rejection rate alone.
"""

import argparse
import json
import statistics
import sys
from collections import Counter, defaultdict
from pathlib import Path

import claude_transcripts as ct


def usage_messages(entries: list[dict]) -> list[dict]:
    """De-duplicated assistant messages with model and token counts."""
    best: dict[str, dict] = {}
    for entry in entries:
        message = entry.get("message")
        if entry.get("type") != "assistant" or entry.get("isSidechain"):
            continue
        if not isinstance(message, dict) or not isinstance(message.get("usage"), dict):
            continue
        model = message.get("model")
        if not model or model == "<synthetic>":
            continue
        usage = message["usage"]
        output = usage.get("output_tokens") or 0
        key = message.get("id") or entry.get("uuid") or str(len(best))
        if key not in best or output > best[key]["output"]:
            best[key] = {
                "key": key,
                "model": model,
                "output": output,
                "context": sum(
                    usage.get(k) or 0
                    for k in (
                        "input_tokens",
                        "cache_read_input_tokens",
                        "cache_creation_input_tokens",
                    )
                ),
                "date": entry.get("timestamp", "")[:10],
            }
    return list(best.values())


def in_range(date: str, since: str, until: str) -> bool:
    return bool(date) and (not since or date >= since) and (not until or date <= until)


def collect(root: Path, since: str, until: str) -> tuple[dict[str, list[dict]], list[ct.PlanCall]]:
    """Gather usage rows per session and plan calls, counting each message/plan once.

    Forked and resumed sessions copy earlier history into a new transcript file, so de-duplicate
    across files (first, i.e. oldest, file wins), not only within one.
    """
    sessions: dict[str, list[dict]] = {}
    plans: list[ct.PlanCall] = []
    seen_messages: set[str] = set()
    seen_plans: set[str] = set()
    for path in ct.find_transcripts(root):
        entries = ct.read_entries(path)
        rows = []
        for m in usage_messages(entries):
            if m["key"] in seen_messages:
                continue
            seen_messages.add(m["key"])
            if in_range(m["date"], since, until):
                rows.append(m)
        if rows:
            sessions[path.stem] = rows
        for p in ct.plan_calls(entries):
            if p.tool_use_id in seen_plans:
                continue
            seen_plans.add(p.tool_use_id)
            if in_range(p.timestamp[:10], since, until):
                plans.append(p)
    return sessions, sorted(plans, key=lambda p: p.timestamp)


def summarize(sessions: dict[str, list[dict]], plans: list[ct.PlanCall]) -> dict:
    per_model: dict[str, dict] = defaultdict(
        lambda: {"messages": 0, "output": 0, "sessions": set()}
    )
    session_totals: dict[str, dict] = {}
    for sid, rows in sessions.items():
        by_model: Counter = Counter()
        for row in rows:
            entry = per_model[row["model"]]
            entry["messages"] += 1
            entry["output"] += row["output"]
            entry["sessions"].add(sid)
            by_model[row["model"]] += row["output"]
        session_totals[sid] = {
            "output": sum(r["output"] for r in rows),
            "context": sum(r["context"] for r in rows),
            "primary_model": by_model.most_common(1)[0][0],
        }
    outputs = [s["output"] for s in session_totals.values()]
    per_primary: dict[str, list[int]] = defaultdict(list)
    for s in session_totals.values():
        per_primary[s["primary_model"]].append(s["output"])
    total_output = sum(outputs) or 1
    return {
        "sessions": len(session_totals),
        "output_tokens": sum(outputs),
        "context_tokens": sum(s["context"] for s in session_totals.values()),
        "output_per_session": {
            "median": int(statistics.median(outputs)) if outputs else 0,
            "mean": int(statistics.fmean(outputs)) if outputs else 0,
        },
        "models": {
            model: {
                "messages": v["messages"],
                "output_tokens": v["output"],
                "share": round(v["output"] / total_output, 3),
                "sessions": len(v["sessions"]),
                "median_output_per_session_when_primary": int(
                    statistics.median(per_primary.get(model, [0]))
                ),
            }
            for model, v in sorted(per_model.items(), key=lambda kv: -kv[1]["output"])
        },
        "plans": {
            "calls": len(plans),
            "approved": sum(p.outcome == "approved" for p in plans),
            "rejected": sum(p.outcome == "rejected" for p in plans),
            "pending": sum(p.outcome == "pending" for p in plans),
            "rejected_follow_up_labels": dict(
                Counter(p.label for p in plans if p.outcome == "rejected").most_common()
            ),
            "median_plan_chars": int(statistics.median([len(p.plan) for p in plans]))
            if plans
            else 0,
        },
    }


def print_report(summary: dict, plans: list[ct.PlanCall], show_plans: bool) -> None:
    out = summary["output_per_session"]
    print(f"sessions with usage: {summary['sessions']}")
    print(
        f"output tokens: {summary['output_tokens']:,}   input+cache tokens: "
        f"{summary['context_tokens']:,}"
    )
    print(f"output tokens per session: median {out['median']:,}  mean {out['mean']:,}")
    print("\nby model:")
    for model, v in summary["models"].items():
        print(
            f"  {model:<22} msgs={v['messages']:<6} output={v['output_tokens']:<10,} "
            f"share={v['share']:.0%}  sessions={v['sessions']}  "
            f"median/session(primary)={v['median_output_per_session_when_primary']:,}"
        )
    p = summary["plans"]
    print(
        f"\nplans: {p['calls']} calls  approved={p['approved']}  rejected={p['rejected']}  "
        f"pending={p['pending']}  median plan chars={p['median_plan_chars']:,}"
    )
    print("  operator's next message after a rejected plan:")
    for label, count in p["rejected_follow_up_labels"].items():
        print(f"    {label:<12} {count}")
    if show_plans:
        print("\nper plan (date, outcome, label, chars, next message):")
        for call in plans:
            print(
                f"  {call.timestamp[:16]} {call.outcome:<9} {call.label:<11} "
                f"{len(call.plan):>6}  {call.next_message.replace(chr(10), ' ')[:80]}"
            )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--root", type=Path, default=ct.DEFAULT_ROOT, help="transcripts directory")
    parser.add_argument("--since", default="", help="first date to include, YYYY-MM-DD")
    parser.add_argument("--until", default="", help="last date to include, YYYY-MM-DD")
    parser.add_argument("--show-plans", action="store_true", help="list every plan with its label")
    parser.add_argument("--json", action="store_true", help="print the summary as JSON")
    args = parser.parse_args()

    if not args.root.is_dir():
        sys.exit(f"transcripts directory not found: {args.root}")
    sessions, plans = collect(args.root, args.since, args.until)
    summary = summarize(sessions, plans)
    if args.json:
        print(json.dumps(summary, indent=2))
    else:
        print_report(summary, plans, args.show_plans)


if __name__ == "__main__":
    main()
