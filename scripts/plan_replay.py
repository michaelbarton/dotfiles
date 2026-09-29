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

  should flag   plans followed by "check the assumptions" (unverified_checkable), a request to
                simplify or summarise (not_reviewable), or missing context (missing_context)
  should pass   plans followed by "ok, execute" (executed as-is)

Reported per label: hit rate (did the reviewer raise the matching flag?) and, on executed
plans, the false-alarm rate (any flag). Labels come from regexes in claude_transcripts.py and
there are only a few dozen plans, so read the numbers as directional: this is better at ruling a
change out than proving one in.

Limits: the reviewer sees only the plan text, with no repository or ticket access. It can judge
"lists unknowns it could have checked" and "not reviewable in a minute", but `missing_context`
usually needs tools, so expect low recall there offline.

Reviewers:
  heuristic  free and deterministic (regexes on the plan text); the baseline to beat
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
        hits = sum(flag in r["review"]["flags"] for r in group)
        report["labels"][label] = {
            "n": len(group),
            "flag": flag,
            "hits": hits,
            "blocking": sum(r["review"].get("blocking") is True for r in group),
        }
    executed = by_label.get("execute", [])
    report["executed_as_is"] = {
        "n": len(executed),
        "any_flag": sum(bool(r["review"]["flags"]) for r in executed),
        "blocking": sum(r["review"].get("blocking") is True for r in executed),
        "by_flag": dict(Counter(f for r in executed for f in r["review"]["flags"])),
    }
    # The separation that matters: does a blocking flag land on plans you complained about more
    # than on plans you executed as-is? (An executed plan can still have loose ends, so the
    # executed set is a noisy negative.)
    complaints = [r for label in TARGETS for r in by_label.get(label, [])]
    report["separation"] = {
        "complaint_plans": len(complaints),
        "complaint_blocking": sum(r["review"].get("blocking") is True for r in complaints),
        "executed_plans": len(executed),
        "executed_blocking": report["executed_as_is"]["blocking"],
    }
    report["unscored"] = dict(
        Counter(r["label"] for r in ok if r["label"] not in {*TARGETS, "execute"})
    )
    return report


def rate(k: int, n: int) -> str:
    return f"{k}/{n} = {k / n:.0%}" if n else "n/a"


def print_report(report: dict, reviewer: str) -> None:
    print(f"reviewer: {reviewer}   errors: {report['errors']}\n")
    print("hit rate (should flag):")
    for label, v in report["labels"].items():
        note = "  (small n)" if v["n"] < SMALL_N else ""
        print(
            f"  {label:<12} -> {v['flag']:<21} {rate(v['hits'], v['n'])}"
            f"   blocking {rate(v['blocking'], v['n'])}{note}"
        )
    ex = report["executed_as_is"]
    note = "  (small n)" if ex["n"] < SMALL_N else ""
    print(f"\nflags on plans executed as-is: {rate(ex['any_flag'], ex['n'])}{note}")
    for flag, count in ex["by_flag"].items():
        print(f"  {flag:<21} {count}")
    sep = report["separation"]
    print(
        "\nblocking flag rate: "
        f"complaint plans {rate(sep['complaint_blocking'], sep['complaint_plans'])} vs "
        f"executed as-is {rate(sep['executed_blocking'], sep['executed_plans'])}"
    )
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
