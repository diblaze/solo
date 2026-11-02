<!-- Parent: ../../AGENTS.md -->
# skills/plan/scripts/

## Purpose
The OpenSpec change scripts that `/solo:plan` and `/solo:execute` run: create a change, validate it, set its status, and call the pinned OpenSpec CLI; plus the shared `gh`/`git` scripts that `/solo:plan`, `/solo:investigate`, `/solo:ship`, `/solo:execute` and `/solo:pr-ready` run: read an issue, create the tracking issue, check every commit. `common.sh` is sourced by every change script here and by the `pr-ready` and `map` scripts.

## Key files
| File | Purpose |
| --- | --- |
| common.sh | Shared guard: needs `rg`, moves to the git root, validates slugs and `Issue:` lines; `tracked_clean`, `write` (honours `--dry-run`), `ensure_label` |
| create-issue.sh | On approval: creates the tracking issue from the proposal unless it names one, then sets `Status: approved`; `--dry-run` prints the writes |
| new-change.sh | Initialises `openspec/` when missing, creates the change, prints its path |
| openspec.sh | Runs OpenSpec 1.14.1: the global binary at that version, else `npx` |
| read-issue.sh | Prints an issue's JSON, then `collaborator <login>` or `outsider <login>` per author; refuses a malformed argument before calling `gh` |
| scripts.test.sh | Offline tests with stub `openspec`/`npx` on `PATH` and throwaway repos |
| set-status.sh | Rewrites `Status:` (and `Issue:`) in `proposal.md`; `done` refuses unticked tasks |
| validate-change.sh | Strict validation plus every scenario named by a task |
| verify-commits.sh | Runs a check at every commit in `<base>..HEAD` in a throwaway worktree; names the first failing commit |

## For AI agents
- Test: `bash skills/plan/scripts/scripts.test.sh`.
- Every slug-taking script (`new-change.sh`, `set-status.sh`, `validate-change.sh`, `create-issue.sh`, `fold.sh`) validates its slug with `slug_ok` (`skills/plan/scripts/common.sh:15`).
- `common.sh` drops an inherited `GIT_DIR` unless `GIT_WORK_TREE` is set (`skills/plan/scripts/common.sh:5`); test harnesses unset the git env at the top (`skills/plan/scripts/scripts.test.sh:6`).
- Bump the OpenSpec pin in one place (`skills/plan/scripts/openspec.sh:6`).

## Dependencies
- Internal: `skills/pr-ready/scripts/fold.sh` (tested from `scripts.test.sh`).
- External: `git`, `rg`, `openspec` or `npx`.
