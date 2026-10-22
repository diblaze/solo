<!-- Parent: ../../AGENTS.md -->
# skills/plan/scripts/

## Purpose
The OpenSpec change scripts that `/solo:plan` and `/solo:execute` run: create a change, validate it, set its status, and call the pinned OpenSpec CLI. `common.sh` is sourced by every change script here and by the `pr-ready` and `map` scripts.

## Key files
| File | Purpose |
| --- | --- |
| common.sh | Shared guard: needs `rg`, moves to the git root, validates slugs and `Issue:` lines |
| new-change.sh | Initialises `openspec/` when missing, creates the change, prints its path |
| openspec.sh | Runs OpenSpec 1.14.1: the global binary at that version, else `npx` |
| scripts.test.sh | Offline tests with stub `openspec`/`npx` on `PATH` and throwaway repos |
| set-status.sh | Rewrites `Status:` (and `Issue:`) in `proposal.md`; `done` refuses unticked tasks |
| validate-change.sh | Strict validation plus every scenario named by a task |

## For AI agents
- Test: `bash skills/plan/scripts/scripts.test.sh`.
- Every slug-taking script (`new-change.sh`, `set-status.sh`, `validate-change.sh`, `fold.sh`) validates its slug with `slug_ok` (`skills/plan/scripts/common.sh:15`).
- `common.sh` drops an inherited `GIT_DIR` unless `GIT_WORK_TREE` is set (`skills/plan/scripts/common.sh:5`); test harnesses unset the git env at the top (`skills/plan/scripts/scripts.test.sh:6`).
- Bump the OpenSpec pin in one place (`skills/plan/scripts/openspec.sh:6`).

## Dependencies
- Internal: `skills/pr-ready/scripts/fold.sh` (tested from `scripts.test.sh`).
- External: `git`, `rg`, `openspec` or `npx`.
