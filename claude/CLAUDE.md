# Global conventions

These apply across projects unless a project's own CLAUDE.md says otherwise.

## Python

- Use `uv`, not `pip`/`poetry`/`pipx`. Standalone scripts declare their own
  dependencies with PEP 723 inline metadata (`# /// script` block) and a
  `#!/usr/bin/env -S uv run --script` shebang, so they run without a venv.
- Format and lint with `ruff` at `--line-length=100`.
- New project scaffolding: `python/scratch_python_project.sh` (linked as
  `~/.bin/scratch_python_project`) or the cookiecutter template under
  `python/cookiecutter/`.

## Task runners

- Projects with a `Justfile` use `just <target>`; from an interactive shell,
  `jn <target>` (a fish function) runs it and sends a completion notification —
  useful for long builds.
- This dotfiles repo itself uses `make` (`make fmt`, `make fmt_check`,
  `make apply`) rather than `just`, since it predates that convention.

## Planning

- In plan mode, call `ExitPlanMode` only when there is an implementation to
  approve. For advice, research, or a question about an existing plan, answer in
  text and end the turn; this overrides plan mode's default of always ending on
  `ExitPlanMode`. The plan review here is reject-then-reply, so a needless
  `ExitPlanMode` costs a rejection.
- Verify before presenting: anything you can check read-only (code, config, a
  query, the docs) gets checked, and the plan states the result with its source.
  Only what cannot be checked is listed as `UNVERIFIED:`, with why.
- Adversarial review: before `ExitPlanMode` on a plan that changes files or
  systems, spawn one fresh-context reviewer with the Agent tool (`Explore`, so
  it is read-only). Give it the plan file path and the operator's original
  request, not your reasoning. Ask it to (1) try to verify every asserted or
  `UNVERIFIED:` claim, (2) find context the plan missed (open PRs, recent
  commits, linked tickets or threads, files never read), and (3) flag anything
  not reviewable in about a minute. It returns at most 15 lines, each with
  evidence. Fold the findings into the plan, and run it once per plan. Skip it
  for trivial single-file changes and for advisory answers.

## Before committing

Run `make fmt` (formats) or `make fmt_check` (verifies, what CI runs) before
committing in this repo. Other projects: use whatever the project's own
formatter/lint target is — check for a `Justfile`, `Makefile`, or `package.json`
scripts before assuming.

## Git

- Conventional, focused commits; explain *why* in the body, not just *what*.
- Don't amend or force-push shared history without being asked.
