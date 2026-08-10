# Cursor and Claude agent configuration

User-level **prompt hooks** (via Claude settings) and **Cursor rules** apply
across all projects when deployed.

## Deployment

Symlink into your home directory:

```bash
ln -sf ~/.dotfiles/claude/settings.json ~/.claude/settings.json
ln -sf ~/.dotfiles/cursor/rules ~/.cursor/rules
```

Or run Ansible with the `hooks` or `setup` tag:

```bash
uv run ansible-playbook -i ~/.dotfiles/ansible/inventory.ini ~/.dotfiles/ansible/dotfiles.yml --tags hooks
```

### Cursor: enable third-party hooks

Hooks live in `~/.claude/settings.json` (Claude Code format). Cursor loads them
when **Settings → Features → Third-party skills** is enabled.

Project-level `.cursor/hooks.json` in a repo can still add project-specific
hooks; global hooks come from `~/.claude/settings.json`.

## What's included

### Hooks (`~/.claude/settings.json`)

| Hook                                 | Event                                 | What it does                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| ------------------------------------ | ------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Plan quality gate (`plan-review.sh`) | `PostToolUse` (Write/Edit)            | When a plan under `.cursor/plans/` or `.claude/plans/` is edited, injects an audit prompt (via `additionalContext`) wrapping the gates defined in `planning.mdc` (single source of truth), with a per-gate PASS/FAIL/N-A verdict contract ending in `PLAN OK` when clean. The full rule is injected on every plan edit — a once-per-session marker would go stale after context compaction.                                                                                                                                                                                                                                                                                                                                               |
| dbt rules (`dbt-rules.sh`)           | `PostToolUse` (Write/Edit)            | When a `.sql`/`.yml` file inside a dbt project (`dbt_project.yml` ancestor) is edited, injects `dbt.mdc` (via `additionalContext`) — Claude Code's equivalent of Cursor's glob-scoped rule loading. Full rule on the first qualifying edit per session; later edits get a one-line reminder of the load-bearing rules (grain test, no repair-loop, plan-sanctioned dedup, reconciliation).                                                                                                                                                                                                                                                                                                                                                |
| Turn tracker (`track-tool-use.sh`)   | `PostToolUse` (Write/Edit/Bash)       | Appends edited file paths and Bash commands to a per-session state file in `$TMPDIR` so the Stop hook knows what happened this turn without parsing the transcript. No output.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| Verify build (`stop-check.sh`)       | `Stop`                                | If `.sql` files inside a dbt project or `.qmd` files were edited this turn and no build/render command ran, blocks the stop once (`decision: block`) with a reminder to run `dbt build` / `quarto render`. Loop-safe by design: allows the stop unconditionally when `stop_hook_active` is set (max one nag per turn) and fails open on any error.                                                                                                                                                                                                                                                                                                                                                                                        |
| Plan critique (`plan-critique.sh`)   | `Stop` + `PostToolUse` (ExitPlanMode) | When a plan file >150 lines was edited this session (path recorded by `plan-review.sh`), blocks the stop once with the 7-gate critique rubric from `plan-critique.mdc` plus hedge-language hints, so the agent revises before handing the plan back rather than ending the turn on a flawed draft. (`Stop` fires after the message has streamed, so the operator does see the first draft — the block buys the revision, not the concealment.) On `ExitPlanMode` it does the reverse: the plan has been presented for approval, so it sets the marker and retires the critique. Loop-safe: honours `stop_hook_active` unconditionally; marker keyed on plan path so each distinct plan gets one critique. Fails open on every error path. |

dbt layer boundaries and other SQL conventions are enforced via **rules**
(`dbt.mdc`), not hooks.

Hook output follows the **Claude Code** JSON contract
(`hookSpecificOutput.additionalContext`, `decision: block`); plain stdout from a
hook never reaches the model. Cursor's own hook protocol differs — these scripts
are written against Claude Code semantics.

### Rules (`~/.cursor/rules/`)

| Rule                | Scope            | What it does                                                                                                                                                                                            |
| ------------------- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `planning.mdc`      | Always applied   | Plan structure (exit criteria, invariants, failure modes + premortem, assumptions & unknowns, outside view), minimal viable change, visualization confirmation                                          |
| `plan-critique.mdc` | On request       | Skeptical 7-gate critique rubric (intelligibility, jargon, provenance, verified claims, traceability, scope, progressive disclosure) — enforced once per long plan via the `plan-critique.sh` Stop hook |
| `dbt.mdc`           | `*.sql`, `*.yml` | Layer boundaries, grain docstrings, testing conventions, anti-patterns                                                                                                                                  |

## Project-specific extensions

Add `.cursor/rules/` or `.cursor/hooks.json` in a project repo for
domain-specific policy. Project hooks override user hooks where Cursor merges
configs.
