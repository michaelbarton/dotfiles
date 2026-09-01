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

## Before committing

Run `make fmt` (formats) or `make fmt_check` (verifies, what CI runs) before
committing in this repo. Other projects: use whatever the project's own
formatter/lint target is — check for a `Justfile`, `Makefile`, or `package.json`
scripts before assuming.

## Git

- Conventional, focused commits; explain *why* in the body, not just *what*.
- Don't amend or force-push shared history without being asked.
