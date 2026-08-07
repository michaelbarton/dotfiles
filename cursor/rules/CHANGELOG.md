# Changelog — agent planning/dbt rules

Rationale log for `cursor/rules/planning.mdc` and `cursor/rules/dbt.mdc`.

Git records *what* changed line-by-line; this file records *why*, and the
alternatives considered and rejected — so a later edit doesn't silently
re-litigate a settled decision. Newest first. Each entry: What / Why /
Considered & rejected.

______________________________________________________________________

## 2026-08-07 — Plan-critique Stop hook and rubric

**What changed**

- Added `cursor/rules/plan-critique.mdc` — a 7-gate skeptical critique rubric
  (intelligibility, jargon, provenance, verified claims, traceability, scope,
  progressive disclosure) with a `<!-- critique ... -->` manifest extracted at
  runtime by the hook.
- Added `claude/hooks/plan-critique.sh` — a `Stop` hook that blocks once per
  plan path per session when the plan exceeds 150 lines, injecting the rubric
  plus hedge-language grep hints. Also registered on
  `PostToolUse(ExitPlanMode)`, where it sets the marker instead of blocking:
  once a plan has been handed to the operator for approval, critiquing it is
  waste, and without this guard the first `Stop` after approval (potentially
  after implementation) would still fire.
- `claude/hooks/plan-review.sh` now writes the plan path to a per-session
  pointer file so the Stop hook can find it, and no longer tells the agent to
  ask the user to fill gaps (close them by reading the code instead).
- Registered the hook in `claude/settings.json`.

**Why**

- Evidence: the 2026-08-06 BAL-1.3 plan took four rounds of operator inline
  notes to converge at 923 lines. The existing `plan-review.sh` PostToolUse hook
  audited section *presence* and passed every round; none of the ~26 operator
  notes were about a missing section. Three load-bearing claims were wrong and
  checkable from source — all caught by the operator, not the agent. A blocking
  skeptical pass before the operator sees the plan addresses the failure mode
  the section-audit hook cannot.

**Considered & rejected**

- *`PreToolUse(ExitPlanMode)`* — rejected: the source conversation called
  `ExitPlanMode` zero times; every turn ended with plain text, so this hook
  would never fire.
- *Extending `plan-review.sh`'s gates* — rejected: PostToolUse can only advise
  via `additionalContext`; it cannot block. Blocking is the only mechanism that
  forces a revision before the operator reads anything.
- *Re-critique on substantial content change* — rejected: risks the nagging loop
  the invariants forbid; marker is keyed on plan path, one critique per path.
- *A separate script for the `ExitPlanMode` marker guard* — rejected: it would
  duplicate the session-id validation, pointer read, and path hashing. The one
  script branches on `hook_event_name` instead.
- *Case-sensitive hedge grep* — fixed, not rejected. Sentence-initial hedges
  ("Probably …", "Unclear whether …") are the common form in prose; a
  case-sensitive match missed 7 of 8 realistic examples, leaving gate 4's
  concrete hint effectively dead.
- *Adding Glossary + Provenance to `planning.mdc`'s manifest* — rejected:
  pushes every plan toward the heavy format; the critique rubric lives in its
  own file (`alwaysApply: false`) so short plans stay short.

______________________________________________________________________

## 2026-07-14 — Make the plan-review gate list single-source

**What changed**

- The audit gate list now lives only in `planning.mdc`, as a
  `<!-- gates ... -->` HTML comment (invisible in Cursor's rendered view).
- `claude/hooks/plan-review.sh` extracts that manifest at runtime and injects it
  in place of its former hardcoded numbered list; it also strips the comment
  from the rule body it injects, and fails loud (`exit 1`) if the manifest is
  missing.

**Why**

- The gate list was duplicated in two files that had to be edited together by
  hand; the premortem-reframing change above required exactly that dual edit.
  Nothing caught a mismatch, so a future rule edit could leave the hook auditing
  against a stale rubric. Deriving the list from the rule makes drift
  structurally impossible.

**Considered & rejected**

- *A CI/`make check` that detects divergence* — rejected: it would need to
  normalize the two deliberately-different naming schemes, and the repo has no
  pre-commit or shell-test harness. Eliminating the second copy is less
  infrastructure and strictly more reliable than detecting drift after the fact.

______________________________________________________________________

## 2026-07-14 — Reframe premortem for analysis work; promote Context & Verification

**What changed**

- Split the Premortem into two framings chosen by what the work produces:
  analysis/report → "this result was shared and the conclusion turned out to be
  wrong because …" (with analysis-specific failure classes); maintained
  pipeline/tool/config → the original "it is 3 months later …".
- Promoted **Context** to a required first section.
- Added **Verification** as its own section (reproduce commands, distinct from
  the done-checklist).
- Synced `claude/hooks/plan-review.sh` gate list to match (now 9 gates).

**Why**

- Evidence: survey of all 54 saved plans in `~/.claude/plans/` (2026-06-15 →
  2026-07-14) plus 216 Claude Code session transcripts. ~80% of the operator's
  work is one-off analysis, data investigation, and report authoring — not
  maintained software — so the "3 months later" premortem framing mismatched the
  common case. The failure that actually bites is a wrong conclusion escaping
  into a report/Slack/validation doc.
- Context appeared in 87% of plans and Verification in 72% despite neither being
  mandated — codifying what plans already do, not adding ceremony.
- The template otherwise showed no friction: grain/fan-out gates catch real bugs
  and the viz/failure gates self-suppress via honest `N/A`.

**Considered & rejected**

- *Work-type "mode selector" at the top of every plan* — rejected as
  over-templating; the existing `N/A` self-suppression already degrades
  gracefully across work types, with no observed friction.
- *Relaxing the 60-second-review rule* — rejected. Plans do run long (median
  ~200 lines) but transcripts show zero complaint, and loosening the rule would
  only license more length.
- *Reintroducing "Outside view"* — rejected; it reappeared organically in ~24%
  of plans but was deliberately cut in #98, so not re-adding without an explicit
  ask.

______________________________________________________________________

## 2026-06-28 — Replace "Outside view" with Success & grain gates (#98)

*(reconstructed from git history)*

**What changed**

- Renamed `Exit criteria` → `Success & exit criteria` (added a one-sentence
  end-state before the done checklist).
- Promoted grain from a sub-bullet inside Invariants to its own standalone gate,
  "What is the grain of the data".
- Dropped the "Outside view" gate (reference-class effort/risk estimation with a
  buffer multiplier).

**Why**

- Grain was getting buried inside Invariants where it was easy to skip; as the
  spec the operator reviews, it needed to stand on its own.
- Outside-view effort estimation wasn't earning its keep in analytical/dbt work.

______________________________________________________________________

## 2026-06-12 — Introduce rule + hook system (#94)

*(reconstructed from git history)*

**What changed**

- Introduced `planning.mdc` and the deployment/hook system: Cursor rules symlink
  and Claude Code PostToolUse/Stop hooks.
- Made `planning.mdc` the single source of truth: the hook substitutes its body
  rather than duplicating the gates in a separate template; dropped an initial
  `claude/prompts/plan-review.md` (Claude Code has no `prompts/` convention).

**Why / Considered & rejected**

- Dropped production-engineering gates as ill-suited to analytical/dbt work:
  **Reversibility**, **System 2 triggers**, and **three-tier boundaries for
  actions** (with a shop-specific "Never do" list).
