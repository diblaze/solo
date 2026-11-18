# Tasks
## 1. /solo:brainstorm skill
- [x] 1.1 Add cases to `tests/guards.test.sh` (E4): `Landscape of distinct options` proves "Landscape of distinct options" (three to five, Cost, Breaks first, Right when, do nothing); `Existing helper cited` proves "Existing helper cited" (`path:line`, `Unverified:`, `solo:explorer`); `Landscape ends on a pick` proves "Landscape ends on a pick" (`## Recommendation`, `## Open questions`); `No file written` proves "No file written" (no code, no files, `/solo:plan` next, no `Write`/`Edit` in `allowed-tools`); add pairs `brainstorm plan` and `brainstorm research` to the boundary list, which proves "Open options question goes to brainstorm" together with the eval case. Verify: `bash tests/guards.test.sh` fails.
- [x] 1.2 Add `evals/brainstorm/prompt.md`, `graders/fires.md`, `graders/not-plan.md`, `graders/not-research.md`, and `not-brainstorm.md` in `evals/plan/graders/` and `evals/research/graders/` (E5). Verify: `bash tests/guards.test.sh`.
- [x] 1.3 Add `skills/brainstorm/SKILL.md` (E1, E3). Verify: `bash tests/guards.test.sh`.
- [x] 1.4 Name it in the `skills/plan/SKILL.md` and `skills/research/SKILL.md` descriptions (E1, E2); `README.md` and `evals/run.sh` counts, Skill reference row, plan and research "Not for" cells; `skills/AGENTS.md` row; `plugin.json` 2.6.0 and description, `marketplace.json` list (E6). Verify: `bash tests/guards.test.sh && bash skills/map/scripts/check-map.sh`.

## 2. Check
- [x] 2.1 `lefthook run pre-push --all-files`
