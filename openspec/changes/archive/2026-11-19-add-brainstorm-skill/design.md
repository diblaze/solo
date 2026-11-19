# Design
## Context
- E1 `skills/research/SKILL.md:3` — "Answer an open question with sourced evidence … Use before picking a library, protocol, or approach." and `:25` "2-4 real candidates … Include "do nothing / use what is already installed"" — the closest neighbour; its options come from sources, not from this codebase.
- E2 `skills/plan/SKILL.md:3` — "Does not edit code — use solo:execute after approval. Does not diagnose a bug — use solo:investigate first" — the "does not" line to extend.
- E3 `skills/investigate/SKILL.md:19` — "Big sweep → delegate to `solo:explorer`, one angle per dispatch, run in parallel." — the sweep pattern to copy.
- E4 `tests/guards.test.sh:205-210` — "Boundary pair without a guard refused" list of pairs — where the new pairs go; `:196-201` the `fires.md` template check.
- E5 `evals/research/prompt.md:1-8` and `evals/plan/graders/not-issues.md` — case and zero-call grader shape.
- E6 `README.md:7` — "**16 skills** … 11 helpers (…)"; `README.md:32-49` Skill reference; `README.md:106` and `evals/run.sh:3` case counts; `skills/AGENTS.md:7-24` Key files; `.claude-plugin/plugin.json:4` description, `.claude-plugin/marketplace.json:10` skill list.

## Goals / Non-Goals
**Goals:**
- One skill that lays out grounded options and stops at a recommendation.

**Non-Goals:**
- Web research inside a brainstorm — `/solo:research` covers it; reopen when an option needs external facts to rank.
- Saving the landscape to a file — reopen when a user asks to keep one.
- Running the prose through a writing pass — reopen when a writer skill exists on the same branch.

## Decisions
- Text checks in `tests/guards.test.sh` prove the contract scenarios: they are skill text, and the routing scenario also has the paid eval case (E4, E5).
- Research keeps sourced, external questions; brainstorm takes approaches inside this codebase. Both "does not" lines name the other (E1, E2).
- Version 2.5.0 to 2.6.0, a new skill.

## Risks / Trade-offs
- The eval prompt sits between three skills; the zero-call graders measure that, but only when the paid suite runs.

## Open Questions
