# Tasks
## 1. Pin OpenSpec 2.1.1
- [x] 1.1 Change `1.14.1` to `2.1.1` in `skills/plan/scripts/scripts.test.sh:19,370,371` (E2) and watch the "Mismatched global CLI bypassed" check fail; verify: `bash skills/plan/scripts/scripts.test.sh` fails
- [x] 1.2 Set `v=2.1.1` in `skills/plan/scripts/openspec.sh:6` (E1); verify: `bash skills/plan/scripts/scripts.test.sh` passes
- [x] 1.3 Update the version text in `skills/plan/SKILL.md:12`, `skills/plan/scripts/AGENTS.md:13`, `skills/AGENTS.md:37`, `README.md:97`; in `README.md:137` also say Node 22.20.0 or newer (E2, E10); verify: `rg -n '1\.14\.1' -g '!openspec/changes/archive/**' -g '!openspec/changes/update-openspec-cli/**'` prints nothing
- [x] 1.4 Commit as `fix(deps): bump OpenSpec CLI to 2.1.1` (Decisions)

## 2. Release docs match release-please (commit `docs(release): deps commits release nothing`)
- [x] 2.1 `README.md:174` drops `deps` from the patch types and says any other type releases nothing (E11); the delta keeps scenarios "Feature commit proposes a minor release" and "Docs-only commits propose no release" unchanged; verify: `bash tests/guards.test.sh`

## 3. Check
- [x] 3.1 `lefthook run pre-push --all-files`
- [x] 3.2 Real run with no stubs: in a `mktemp -d` git repo with one commit on a branch, run `new-change.sh add-x`, write proposal/tasks/spec with ticked tasks, `validate-change.sh add-x`, `set-status.sh add-x done none`, commit, `fold.sh add-x`; each exits 0, stderr shows no `using npx` when global 2.1.1 is installed, and `openspec/changes/archive/<date>-add-x/` plus `openspec/specs/<cap>/spec.md` exist
