You just edited a plan document. Before any implementation, audit it
against the planning rule below (the canonical gate definitions). Be
strict: a gate passes ONLY if you can quote the line(s) that satisfy it.
Paraphrases, "implied somewhere," or "this is obvious" do NOT count.

---

{{PLANNING_RULE}}

---

## Audit output

If every applicable gate passes: output exactly `PLAN OK` on a single
line and nothing else.

Otherwise: output a bulleted gap list. Each bullet:
`Gate <name>: <specific gap>`. Then stop and ask the user to fill the
gaps before implementing.
