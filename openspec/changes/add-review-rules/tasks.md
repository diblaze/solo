# Tasks
## 1. Rules script and review wiring
- [x] 1.1 Add `skills/review/scripts/review-md.test.sh` (E5): throwaway repo whose base is `refs/remotes/origin/main`. Cases: `::Rules read from the base ref` proves "Rules read from the base ref"; `::Nearest rules file per path` proves "Nearest rules file per path" (exact stdout); `::No rules file prints nothing` proves "No rules file prints nothing"; `::Changed files found on the branch` proves "Changed files found on the branch"; `::Unknown base ref refused` proves "Unknown base ref refused"; `::Unrelated history refused` proves "Unrelated history refused" (orphan branch). Verify: it fails on the missing script.
- [x] 1.2 Add `skills/review/scripts/review-md.sh` per the design decisions (E7). Verify: `bash skills/review/scripts/review-md.test.sh`.
- [x] 1.3 In `tests/guards.test.sh` add a `review` READONLY entry and a case `Rules passed to the reviewer` that proves "Rules passed to the reviewer": review's body runs `review-md.sh --base` before the dispatch step and names the rules text as a dispatch input; `agents/reviewer.md` names `REVIEW.md` (E3, E4). Verify: it fails.
- [x] 1.4 `skills/review/SKILL.md`: `allowed-tools` with the script, `git fetch origin <base>` with any `origin/` prefix stripped and one ref for the diff and the rules, a rules step before dispatch, the rules text in the dispatch (E1, E2); `agents/reviewer.md`: follow the prompt's `REVIEW.md` rules (E4). Verify: `bash tests/guards.test.sh`.
- [x] 1.5 Wire and document (E6): `lefthook.yml` both `tests` jobs, CI tests step, root `AGENTS.md` Tests line, `README.md` Scripts row and Tests line, `skills/AGENTS.md` review row, `.claude-plugin/plugin.json` 2.6.0. Verify: `bash skills/map/scripts/check-map.sh`.

## 2. Check
- [x] 2.1 `lefthook run pre-push --all-files && bash skills/review/scripts/review-md.test.sh`
