# Design
## Context
- E1 `skills/docs/SKILL.md:25-26` — "## 4. Voice / Short sentences, active, present tense. No "simply", "just", "robust", "seamless"." — where the docs pass goes.
- E2 `skills/adr/SKILL.md:37-41` — "## Rules … Keep it under a page." — where the ADR pass goes.
- E3 `skills/pr-ready/SKILL.md:37-39` — "## 5. Open … Write the body to a file outside the repo" — where the PR body pass goes; `tests/guards.test.sh:21-26` checks section 5.
- E4 `tests/guards.test.sh` "Chaining skill without a guard refused" — "A skill that chains into the expected one would fire it too, so its case must refuse the chaining skill." — docs, adr and pr-ready now chain into writer.
- E5 `LICENSE:3` — "Copyright (c) 2026 diblaze"; the pattern catalog is derived from an MIT-licensed upstream whose notice must ship with it.
- E6 `README.md:7` count, `README.md:32-49` Skill reference, `README.md:106` and `evals/run.sh:3` case counts, `README.md:167` License; `skills/AGENTS.md:7-24`; `.claude-plugin/plugin.json:4`, `.claude-plugin/marketplace.json:10`.

## Goals / Non-Goals
**Goals:**
- One prose pass, rewrite or review, and the three writing steps routed through it.

**Non-Goals:**
- Running review replies or issue bodies through it — reopen when solo posts those.
- A lint script for dashes — the rule is skill text; reopen when a dash ships in generated docs.

## Decisions
- Pattern catalog in `references/patterns.md`, read on demand, so the skill text stays short.
- Text checks in `tests/guards.test.sh` prove the contract scenarios; the routing scenario also has the paid eval case (E4).
- `NOTICE` at the root carries the upstream copyright and MIT text (E5); the two derived files point to it.
- Version 2.5.0 to 2.6.0, a new skill.

## Risks / Trade-offs
- A writer pass on a PR body can reword a requirement name; embedded mode keeps headings and prefixes but not every term, so the PR step still checks the `Closes` line through `open-pr.sh`.

## Open Questions
