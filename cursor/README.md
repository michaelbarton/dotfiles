# Cursor, Claude Code and Codex agent configuration

User-level **prompt hooks** (via Claude settings and Codex `hooks.json`) and
**Cursor rules** apply across all projects when deployed. One set of hook
scripts under `claude/hooks/` serves all three agents; only the registration
file differs.

## Deployment

Symlink into your home directory:

```bash
ln -sf ~/.dotfiles/claude/settings.json ~/.claude/settings.json
ln -sf ~/.dotfiles/codex/hooks.json ~/.codex/hooks.json
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

### Codex: a separate registration file

Codex does not read `~/.claude/settings.json` — only Cursor does. It has its own
hooks engine (`codex features list` → `hooks stable`) reading
`~/.codex/hooks.json`, with the same event names, the same input field names
(`session_id`, `cwd`, `tool_name`, `tool_input`, `stop_hook_active`) and the
same output contract as Claude Code. `codex/hooks.json` registers the same
scripts against that engine. Two differences are load-bearing:

- **Matchers are `*`.** Codex has no `Write`, `Edit`, `Bash` or `ExitPlanMode`
  tool, and its tool names shift with feature flags — with code mode enabled,
  edits and commands both arrive as `exec` cells running JavaScript. Porting the
  Claude matchers would silently match nothing, so each script gates on the
  payload itself instead.
- **`plan-critique.sh` is not registered on `PostToolUse`.** That registration
  exists to retire a critique once `ExitPlanMode` has presented the plan for
  approval, and Codex has no equivalent event. Under Codex the critique fires
  once at `Stop` and is never retired early.

Each entry also carries a `statusMessage`, which Codex shows in the terminal
while the hook runs. Claude Code has no equivalent field, so there a hook that
gates a command is silent until it either passes or blocks.

Codex also gates hooks behind a trust prompt: its hooks panel tracks a hash per
hook and shows *"Modified since last trusted — review required"*. Re-trust there
after any `make apply` that changes `codex/hooks.json`.

## What's included

### Hooks (`~/.claude/settings.json`, `~/.codex/hooks.json`)

| Hook                                 | Event                                 | What it does                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| ------------------------------------ | ------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Plan quality gate (`plan-review.sh`) | `PostToolUse`                         | When a plan under `.cursor/plans/` or `.claude/plans/` is edited, injects an audit prompt (via `additionalContext`) wrapping the gates defined in `planning.mdc` (single source of truth), with a per-gate PASS/FAIL/N-A verdict contract ending in `PLAN OK` when clean. The full rule is injected on every plan edit — a once-per-session marker would go stale after context compaction. Gates on `tool_input.file_path` where the agent supplies one; Codex supplies none, so it falls back to the plan directories under `cwd`, newest file modified in the last minute.                                                                                                                                                             |
| dbt rules (`dbt-rules.sh`)           | `PostToolUse` (Write/Edit)            | When a `.sql`/`.yml` file inside a dbt project (`dbt_project.yml` ancestor) is edited, injects `dbt.mdc` (via `additionalContext`) — Claude Code's equivalent of Cursor's glob-scoped rule loading. Full rule on the first qualifying edit per session; later edits get a one-line reminder of the load-bearing rules (grain test, no repair-loop, plan-sanctioned dedup, reconciliation).                                                                                                                                                                                                                                                                                                                                                |
| Turn tracker (`track-tool-use.sh`)   | `PostToolUse` (Write/Edit/Bash)       | Appends edited file paths and Bash commands to a per-session state file in `$TMPDIR` so the Stop hook knows what happened this turn without parsing the transcript. No output.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| Verify build (`stop-check.sh`)       | `Stop`                                | If `.sql` files inside a dbt project or `.qmd` files were edited this turn and no build/render command ran, blocks the stop once (`decision: block`) with a reminder to run `dbt build` / `quarto render`. Loop-safe by design: allows the stop unconditionally when `stop_hook_active` is set (max one nag per turn) and fails open on any error.                                                                                                                                                                                                                                                                                                                                                                                        |
| Plan critique (`plan-critique.sh`)   | `Stop` + `PostToolUse` (ExitPlanMode) | When a plan file >150 lines was edited this session (path recorded by `plan-review.sh`), blocks the stop once with the 7-gate critique rubric from `plan-critique.mdc` plus hedge-language hints, so the agent revises before handing the plan back rather than ending the turn on a flawed draft. (`Stop` fires after the message has streamed, so the operator does see the first draft — the block buys the revision, not the concealment.) On `ExitPlanMode` it does the reverse: the plan has been presented for approval, so it sets the marker and retires the critique. Loop-safe: honours `stop_hook_active` unconditionally; marker keyed on plan path so each distinct plan gets one critique. Fails open on every error path. |

dbt layer boundaries and other SQL conventions are enforced via **rules**
(`dbt.mdc`), not hooks.

Hook output follows the **Claude Code** JSON contract
(`hookSpecificOutput.additionalContext`, `decision: block`); plain stdout from a
hook never reaches the model. Codex implements the same contract, so the scripts
are shared verbatim. Cursor's own hook protocol differs — these scripts are
written against Claude Code semantics.

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
