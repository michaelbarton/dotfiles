# Changelog — agent planning/dbt rules

Rationale log for `cursor/rules/planning.mdc` and `cursor/rules/dbt.mdc`.

Git records *what* changed line-by-line; this file records *why*, and the
alternatives considered and rejected — so a later edit doesn't silently
re-litigate a settled decision. Newest first. Each entry: What / Why /
Considered & rejected.

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
