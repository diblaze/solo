<!-- Parent: ../../AGENTS.md -->
# skills/pr-ready/scripts/

## Purpose
The scripts `/solo:pr-ready` runs to finish a branch: fold the change's delta specs into `openspec/specs/` and archive it, then push and open or update the labelled PR.

## Key files
| File | Purpose |
| --- | --- |
| fold.sh | Archives the change and commits `docs(spec): fold <slug>`; refuses unticked tasks, a Status other than done, tracked changes, or untracked files under `openspec/` (other untracked files are ignored) |
| open-pr.sh | Pushes and opens the PR labelled by commit type and assigned to `@me`; refuses tracked changes, ignores untracked files; `--dry-run` prints the writes |
| open-pr.test.sh | Offline test with a local bare origin and a stub `gh` |

## For AI agents
- Test: `bash skills/pr-ready/scripts/open-pr.test.sh` (`fold.sh` is covered by `skills/plan/scripts/scripts.test.sh`).
- Both scripts source `skills/plan/scripts/common.sh` (`skills/pr-ready/scripts/fold.sh:8`, `skills/pr-ready/scripts/open-pr.sh:23`).
- `open-pr.sh` refuses a body missing the archived proposal's `Closes owner/repo#n` (`skills/pr-ready/scripts/open-pr.sh:41`).
- Every write goes through `write()` so `--dry-run` stays honest (`skills/plan/scripts/common.sh:19`).

## Dependencies
- Internal: `skills/plan/scripts/` (`common.sh`, `openspec.sh`).
- External: `git`, `gh`, `rg`, `openspec` or `npx`.
