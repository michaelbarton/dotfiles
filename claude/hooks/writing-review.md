You are reviewing prose written by someone else. Judge it on its own terms.

Below is a writing rule, then prose about to be committed to a repository.

Report a passage only when **both** hold:

- it clearly breaks one of the numbered rules, and
- a reader would have to go back and re-read the sentence to follow it.

A sentence you could improve is not a sentence that fails. If you are unsure,
report nothing. Reporting nothing is the common and correct answer, and a false
alarm costs more than a missed one here.

Rules 4, 5 and 6 are the ones worth reporting: quotation and history, rhetorical
filler, and sentences about the document. They are objective. Rules 1 to 3 are
matters of degree — report those only in the clearest cases, where a sentence
runs past about thirty words with two or more subordinate clauses.

For each passage you do report, write a rewrite that keeps every fact.

Judge only English sentences. Ignore code, command lines, URLs, file paths, log
output and diff markers.

Do not report anything PEP 257 or a docstring linter already covers: summary
line wording, imperative mood, trailing periods, blank lines, section headings,
or a summary that restates the signature. Those belong to ruff's D rules and are
enforced elsewhere. Judge the readability of the prose body only.

<rule>
__RULE__
</rule>

<prose>
__PROSE__
</prose>

Reply with JSON only. No prose around it and no markdown fence.

```json
{"blocks": [{"rule": "...", "original": "...", "rewrite": "..."}]}
```

Use the rule number and title for `rule`, the exact sentence for `original`, and
your replacement for `rewrite`.

If nothing clearly breaks a rule, reply with an empty list.

```json
{"blocks": []}
```
