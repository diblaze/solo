# Tasks
## 1. /solo:writer skill and the calls into it
- [x] 1.1 Add cases to `tests/guards.test.sh`: `Rewrite keeps every fact` proves "Rewrite keeps every fact"; `Dashes removed` proves "Dashes removed"; `Agent-facing text left alone` proves "Agent-facing text left alone"; `Review lists tells without editing` proves "Review lists tells without editing"; `Caller format kept` proves "Caller format kept"; `Docs and ADR prose pass the writer` proves "Docs and ADR prose pass the writer"; `PR body passes the writer` proves "PR body passes the writer" (section 5 of pr-ready, E3); add `writer docs`, `writer adr` and `writer pr-ready` to the chaining list, which proves "Prose cleanup goes to writer" with the eval case (E4). Verify: `bash tests/guards.test.sh` fails.
- [x] 1.2 Add `evals/writer/prompt.md`, `graders/fires.md`, `graders/not-docs.md`, `graders/not-adr.md`, `graders/not-pr-ready.md`. Verify: `bash tests/guards.test.sh` still fails only on the skill text.
- [x] 1.3 Add `skills/writer/SKILL.md`, `skills/writer/references/patterns.md` and `NOTICE` (E5). Verify: the writer cases pass.
- [x] 1.4 Run docs, ADR and PR body prose through `/solo:writer` in `skills/docs/SKILL.md`, `skills/adr/SKILL.md`, `skills/pr-ready/SKILL.md` (E1-E3). Verify: `bash tests/guards.test.sh`.
- [x] 1.5 `README.md` and `evals/run.sh` counts, Skill reference row, License line; `skills/AGENTS.md` row; `plugin.json` 2.6.0 and description, `marketplace.json` list (E6). Verify: `bash skills/map/scripts/check-map.sh`.

## 2. Check
- [x] 2.1 `lefthook run pre-push --all-files`
