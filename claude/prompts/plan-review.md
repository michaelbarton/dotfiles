You just edited a plan document. Before any implementation, audit the plan
against the gates below. Be strict: a gate passes ONLY if you can quote the
line(s) that satisfy it. Paraphrases, "implied somewhere," or "this is
obvious" do NOT count.

## Required gates (every plan)

1. **Exit criteria** — at least one falsifiable check (specific command
   succeeds, diff matches, render produces expected output). Reject vibes
   like "works as expected" or "looks right."
2. **Invariants** — explicit list of what must not change (schemas, public
   APIs, file paths, observed behavior).
3. **Failure modes** — concrete risks AND a Premortem in the form: "It is
   3 months later and this failed because …" with top 2–3 reasons. Both
   required.
4. **Assumptions & unknowns** — what is assumed true, what is unverified,
   what would invalidate the plan.
5. **Outside view** — reference class (similar tasks or repo history),
   what usually breaks for that class, realistic buffer vs best case.
6. **Minimal viable change** — simplest design described before any
   optional extras.
7. **Substitution check** — plan addresses the user's actual ask, not an
   easier adjacent problem.

## Conditional gates

Required if the plan changes grain, schema, deletes data, or touches
production:

8. **Reversibility** — concrete rollback path.
9. **System 2 triggers** — steps that require explicit human approval
   before execution.

## Output format

- If every applicable gate passes: output exactly `PLAN OK` on a single
  line and nothing else.
- Otherwise: output a bulleted list. Each bullet:
  `Gate N (<short name>): <specific gap>`. Then stop and ask the user to
  fill the gaps before implementing.

Do not begin implementation until the plan passes.
