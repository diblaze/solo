<!-- Parent: ../AGENTS.md -->
# skills/

## Purpose
One folder per `/solo:*` skill. Each holds a `SKILL.md` (frontmatter `name` and `description`, then the steps) and, where a step needs a CLI, a `scripts/` folder that the skill runs by path from its base directory. The gate skills chain as plan, execute, review, pr-ready; the rest are helpers called inside or around those gates.

## Key files
| File | Purpose |
| --- | --- |
| adr/ | Architecture decision record into `docs/adr/` |
| docs/ | README, feature or API docs from codebase evidence |
| execute/ | Gate 2: implement an approved OpenSpec change, review, commit |
| gap-analysis/ | Compare what exists against what was specified |
| investigate/ | Evidence-first root-cause hunt; emits a fix plan |
| map/ | Per-directory AGENTS.md map, checked by `scripts/check-map.sh` |
| plan/ | Gate 1: dispatch the planner; holds the shared change scripts |
| pr-ready/ | Pre-PR gate: slop, review, fold specs, open the PR |
| refactor/ | Behavior-preserving restructuring |
| research/ | Sourced answer to an open question, ending on a recommendation |
| review/ | Gate 3: dispatch the reviewer on the branch diff |
| ship/ | Whole pipeline in one command |
| slop/ | Deletion-first cleanup of AI slop |
| standard/ | Root AGENTS.md `## Coding standard` |
| tdd/ | Red-green-refactor with an observed-failure gate |

## For AI agents
- Test: `lefthook run pre-push --all-files`.
- Skills run CLI steps through scripts (their own or `plan/scripts/`), never retyped commands (`skills/plan/SKILL.md:9`, `skills/execute/SKILL.md:34`).
- Skill text is guarded by `tests/guards.test.sh`; a reworded rule may need its case updated there (`tests/guards.test.sh:2`).

## Dependencies
- Internal: `agents/` (subagents the skills dispatch), `openspec/` (changes the gate skills read and fold).
- External: `git`, `gh`, `rg`, OpenSpec 1.14.1 (`skills/plan/scripts/openspec.sh:6`).
