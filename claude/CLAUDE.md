# Global conventions

These apply across projects unless a project's own CLAUDE.md says otherwise.

- Use `uv`, not `pip`/`poetry`/`pipx`. For standalone Python scripts, see the
  `uv-scripts` skill.
- Run the project's own formatter/lint target before committing (check for a
  `Justfile`, `Makefile`, or `package.json` scripts).

## Planning

- In plan mode, call `ExitPlanMode` only when there is an implementation to
  approve. For advice, research, or a question about an existing plan, answer in
  text and end the turn; this overrides plan mode's default of always ending on
  `ExitPlanMode`. The plan review here is reject-then-reply, so a needless
  `ExitPlanMode` costs a rejection.

## Git

- Conventional, focused commits; explain *why* in the body, not just *what*.
- Don't amend or force-push shared history without being asked.
