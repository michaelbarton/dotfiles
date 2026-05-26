# Cursor and Claude agent configuration

User-level **prompt hooks** (via Claude settings) and **Cursor rules** apply across all projects when deployed.

## Deployment

Symlink into your home directory:

```bash
ln -sf ~/.dotfiles/claude/settings.json ~/.claude/settings.json
ln -sf ~/.dotfiles/cursor/rules ~/.cursor/rules
```

Or run Ansible with the `hooks` or `setup` tag:

```bash
./apply_ansible hooks
```

### Cursor: enable third-party hooks

Hooks live in `~/.claude/settings.json` (Claude Code format). Cursor loads them when **Settings → Features → Third-party skills** is enabled.

Project-level `.cursor/hooks.json` in a repo can still add project-specific hooks; global hooks come from `~/.claude/settings.json`.

## What's included

### Hooks (`~/.claude/settings.json`)

| Hook | Event | What it does |
|------|-------|--------------|
| Plan quality gate | `PostToolUse` (Write/Edit) | When a plan under `.cursor/plans/` or `.claude/plans/` is edited, audits it against the gates defined in `planning.mdc` (single source of truth). The hook script inlines the rule body and wraps it with audit framing + `PLAN OK` / gap-list output contract. |
| Verify build | `Stop` | Reminds the agent to run build/render if `.sql`, `.yml`, or `.qmd` files were modified |

dbt layer boundaries and other SQL conventions are enforced via **rules** (`dbt.mdc`), not hooks.

### Rules (`~/.cursor/rules/`)

| Rule | Scope | What it does |
|------|-------|--------------|
| `planning.mdc` | Always applied | Plan structure (exit criteria, invariants, failure modes + premortem, assumptions & unknowns, outside view), minimal viable change, visualization confirmation |
| `dbt.mdc` | `*.sql`, `*.yml` | Layer boundaries, grain docstrings, testing conventions, anti-patterns |

## Project-specific extensions

Add `.cursor/rules/` or `.cursor/hooks.json` in a project repo for domain-specific policy. Project hooks override user hooks where Cursor merges configs.
