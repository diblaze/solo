# Proposal

Status: approved
Issue: diblaze/solo#15

## Why
Nothing measures whether the 16 `/solo:*` skills fire on natural phrasing, and several have overlapping scopes (slop/refactor/review, investigate/research/gap-analysis, plan/ship, docs/adr/map, issues/plan). The skill descriptions are about to be rewritten in another change; a trigger suite run before and after it shows whether routing got better or worse.

## What Changes
- Add an `evals/` suite: one trigger case per skill (16), each with a free "skill fired" grader and, on the overlapping pairs, free "neighbour must not fire" graders; no judge-model graders
- Every case grants only the skill tool and stops within 3 turns and 120 seconds, so no case can run a shell, write files, push, open a PR or touch an issue
- Add `evals/run.sh`: runs the suite one arm, report kept local, a cost ceiling, and shell/write/web/subagent tools disallowed even if granted; extra flags (`--case`, `--runs`, `--model`) pass through
- `tests/guards.test.sh` refuses a skill without a case, a case outside the trigger limits, a missing boundary guard, a runner without its tool lock, and any hook or CI step that runs the suite
- Nothing in lefthook or CI calls a model; `evals/results/` is gitignored
- README, root `AGENTS.md`, lefthook glob and plugin version (2.4.0, after `modernize-skill-frontmatter` takes 2.3.0) updated

## Capabilities
### New Capabilities
- `skill-evals`: the trigger-accuracy suite, its static coverage and limit checks, and the rule that automated checks never spend model usage
### Modified Capabilities

## Impact
New `evals/<skill>/prompt.md` + `evals/<skill>/graders/*.md` (16 cases), `evals/run.sh`. Edits: `tests/guards.test.sh`, `.gitignore`, `lefthook.yml` (pre-commit glob), `AGENTS.md` (Map row, Tests line), `README.md` (Scripts row, Tests line), `.claude-plugin/plugin.json` (2.2.0 to 2.4.0). No new dependency; running the suite needs Claude Code 2.1.269+ and spends model usage. No CI change.
