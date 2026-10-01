#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""Replay historical plans through a candidate plan reviewer and score it.

Your session transcripts hold the full text of every plan presented for approval and what you
said next. This treats them as a small labelled regression set for plan-review changes (a new
planning rubric, an adversarial reviewer prompt, a CLAUDE.md rule) so a change is tested before
it is adopted:

  should block  plans you complained about: "check the assumptions", a request to simplify or
                summarise, missing context, or `NOTE:` lines left in the plan file
  should pass   plans executed as-is: "ok, execute", or approved with no objection

The headline is a 2x2 confusion matrix on "did the reviewer set blocking?", set beside the
trivial reviewer that blocks every plan. Most plans get complained about, so blocking everything
already scores well; a reviewer is only useful if its precision clearly beats that base rate.
Per-label rows show which flag it raised for the three typed complaints. Labels come from
regexes in claude_transcripts.py and there are only a few dozen plans, so read the numbers as
directional: this is better at ruling a change out than proving one in.

Limits: the reviewer sees only the plan text, with no repository or ticket access. It can judge
"lists unknowns it could have checked" and "not reviewable in a minute", but `missing_context`
usually needs tools, so expect low recall there offline.

Reviewers:
  heuristic  free and deterministic (regexes on the plan text); it flags almost every plan, so it
             behaves like block-everything and is a sanity check, not the bar to beat
  claude     one `claude -p` call per plan (no tools, no session persisted); costs tokens

Transcripts contain work content: results print locally and `--out` writes wherever you point
it. Keep that file out of the repo.
"""

import argparse
import json
import re
import subprocess
import sys
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import claude_transcripts as ct

FLAGS = ("unverified_checkable", "not_reviewable", "missing_context")
TARGETS = {
    "assumptions": "unverified_checkable",
    "simplify": "not_reviewable",
    "context": "missing_context",
}
COMPLAINT_LABELS = (*TARGETS, "notes")
MIN_PLAN_CHARS = 200
SMALL_N = 10

REVIEWER_PROMPT = """You are an adversarial reviewer of an engineering plan that an operator is \
about to be asked to approve. You can see only the plan text below.

Raise a flag only if you can quote plan text that justifies it:
- unverified_checkable: the plan lists an assumption, unknown, or UNVERIFIED item that could \
have been checked read-only (reading code or config, running a read-only query, fetching \
docs) before presenting the plan.
- not_reviewable: the plan cannot be reviewed in about a minute: no short plain-language \
summary up front, dense detail first, jargon without definitions, or work already completed \
mixed in with what is left.
- missing_context: the plan's own text shows it ignored something it references (a ticket, \
thread, PR, comment, earlier plan) or contradicts its stated goal.

Set "blocking" to true only if a step or decision in the plan depends on the flagged item AND \
you can name the read-only command or file that would settle it; presenting the plan without \
settling it would send the operator into a wrong or wasted approval. Loose ends that no step \
depends on are not blocking.

Reply with only a JSON object, no prose and no code fence:
{"flags": [<zero or more of "unverified_checkable", "not_reviewable", "missing_context">], \
"blocking": <true or false>, "reason": "<one sentence>"}

PLAN:
"""


def heuristic_review(plan: str) -> dict:
    flags = []
    if re.search(r"unverified|not (yet )?verified|assum(e|ption)|unknown", plan, re.IGNORECASE):
        flags.append("unverified_checkable")
    if len(plan) > 8000 or plan.count("\n") > 150:
        flags.append("not_reviewable")
    return {"flags": flags, "blocking": bool(flags), "reason": "regex heuristic"}


def claude_review(plan: str, model: str, effort: str, timeout: int) -> dict:
    cmd = ["claude", "-p", "--no-session-persistence", "--tools", "", "--model", model]
    cmd += ["--effort", effort]
    try:
        proc = subprocess.run(
            cmd,
            input=REVIEWER_PROMPT + plan,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,  # a non-zero exit is reported per plan below, not raised
        )
    except (subprocess.TimeoutExpired, OSError) as exc:
        return {"flags": [], "error": f"{type(exc).__name__}: {exc}"}
    match = re.search(r"\{.*\}", proc.stdout, re.DOTALL)
    if proc.returncode != 0 or not match:
        return {"flags": [], "error": f"exit {proc.returncode}: {proc.stdout[:120]!r}"}
    try:
        data = json.loads(match.group(0))
    except json.JSONDecodeError:
        return {"flags": [], "error": f"unparseable reply: {proc.stdout[:120]!r}"}
    flags = [f for f in data.get("flags", []) if f in FLAGS]
    return {
        "flags": flags,
        "blocking": bool(flags) and data.get("blocking") is True,
        "reason": str(data.get("reason", ""))[:200],
    }


def score(rows: list[dict]) -> dict:
    ok = [r for r in rows if "error" not in r["review"]]
    by_label: dict[str, list[dict]] = defaultdict(list)
    for r in ok:
        by_label[r["label"]].append(r)
    report: dict = {"errors": len(rows) - len(ok), "labels": {}}
    for label, flag in TARGETS.items():
        group = by_label.get(label, [])
        report["labels"][label] = {
            "n": len(group),
            "flag": flag,
            "hits": sum(flag in r["review"]["flags"] for r in group),
        }
    notes = by_label.get("notes", [])
    report["notes"] = {"n": len(notes), "by_flag": flag_counts(notes)}
    executed = by_label.get("execute", [])
    report["executed_as_is"] = {"n": len(executed), "by_flag": flag_counts(executed)}

    complaints = [r for label in COMPLAINT_LABELS for r in by_label.get(label, [])]
    blocked = lambda rs: sum(r["review"].get("blocking") is True for r in rs)
    tp, fp = blocked(complaints), blocked(executed)
    n_pos, n_neg = len(complaints), len(executed)
    report["matrix"] = {
        "tp": tp,
        "fn": n_pos - tp,
        "fp": fp,
        "tn": n_neg - fp,
        "base_rate": n_pos / (n_pos + n_neg) if n_pos + n_neg else None,
    }
    report["unscored"] = dict(
        Counter(r["label"] for r in ok if r["label"] not in {*COMPLAINT_LABELS, "execute"})
    )
    return report


def flag_counts(rows: list[dict]) -> dict:
    return dict(Counter(f for r in rows for f in r["review"]["flags"]))


def rate(k: int, n: int) -> str:
    return f"{k}/{n} = {k / n:.0%}" if n else "n/a"


def print_report(report: dict, reviewer: str) -> None:
    m = report["matrix"]
    n_pos, n_neg = m["tp"] + m["fn"], m["fp"] + m["tn"]
    print(f"reviewer: {reviewer}   errors: {report['errors']}\n")
    print("did the reviewer block?                you complained    you executed as-is")
    print(f"  blocked                              {m['tp']:>8}          {m['fp']:>8}")
    print(f"  passed                               {m['fn']:>8}          {m['tn']:>8}")
    base = m["base_rate"]
    precision = m["tp"] / (m["tp"] + m["fp"]) if m["tp"] + m["fp"] else None
    pct = lambda x: "n/a" if x is None else f"{x:.0%}"
    print(
        f"\n  recall (complaints caught)    {rate(m['tp'], n_pos)}"
        f"\n  false alarms on executed      {rate(m['fp'], n_neg)}"
        f"\n  precision when it blocks      {pct(precision)}"
        f"\n  block-everything precision    {pct(base)}   <- the bar to beat"
    )
    if n_pos < SMALL_N or n_neg < SMALL_N:
        print(f"  (small n: {n_pos} complaints, {n_neg} executed)")

    print("\nflag raised, by what you said:")
    for label, v in report["labels"].items():
        print(f"  {label:<12} -> {v['flag']:<21} {rate(v['hits'], v['n'])}")
    notes = report["notes"]
    print(f"  {'notes':<12} -> any flag: {notes['by_flag'] or '{}'}  (n={notes['n']})")
    ex = report["executed_as_is"]
    print(f"  executed     -> flags raised anyway: {ex['by_flag'] or '{}'}  (n={ex['n']})")
    print(f"\nunscored labels (ambiguous): {report['unscored']}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--root", type=Path, default=ct.DEFAULT_ROOT, help="transcripts directory")
    parser.add_argument("--reviewer", choices=("heuristic", "claude"), default="heuristic")
    parser.add_argument("--model", default="sonnet", help="model for --reviewer claude")
    parser.add_argument("--effort", default="low", help="effort for --reviewer claude")
    parser.add_argument("--jobs", type=int, default=4, help="parallel claude calls")
    parser.add_argument("--timeout", type=int, default=180, help="seconds per claude call")
    parser.add_argument("--since", default="", help="first plan date, YYYY-MM-DD")
    parser.add_argument("--limit", type=int, default=0, help="review at most N plans (0 = all)")
    parser.add_argument("--out", type=Path, help="write per-plan results as JSON here")
    args = parser.parse_args()

    if not args.root.is_dir():
        sys.exit(f"transcripts directory not found: {args.root}")
    plans = [
        p
        for p in ct.unique_plan_calls(args.root)
        if len(p.plan) >= MIN_PLAN_CHARS and p.timestamp[:10] >= args.since
    ]
    if args.limit:
        plans = plans[-args.limit :]
    if not plans:
        sys.exit("no plans with text found")

    if args.reviewer == "claude":
        print(f"reviewing {len(plans)} plans with claude ({args.model}, effort {args.effort})...")

        def review(p: ct.PlanCall) -> dict:
            return claude_review(p.plan, args.model, args.effort, args.timeout)

        with ThreadPoolExecutor(max_workers=max(1, args.jobs)) as pool:
            reviews = list(pool.map(review, plans))
    else:
        reviews = [heuristic_review(p.plan) for p in plans]

    rows = [
        {
            "date": p.timestamp[:16],
            "tool_use_id": p.tool_use_id,
            "outcome": p.outcome,
            "label": p.label,
            "plan_chars": len(p.plan),
            "next_message": p.next_message[:160],
            "notes": len(p.notes),
            "review": review,
        }
        for p, review in zip(plans, reviews)
    ]
    print_report(score(rows), args.reviewer)
    if args.out:
        args.out.write_text(json.dumps(rows, indent=2), encoding="utf-8")
        print(f"\nper-plan results written to {args.out}")


if __name__ == "__main__":
    main()
