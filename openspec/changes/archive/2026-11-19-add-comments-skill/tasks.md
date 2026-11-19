# Tasks
## 1. threads.sh and the /solo:comments skill
- [x] 1.1 Add `skills/comments/scripts/threads.test.sh` (E4): stub `gh` logging argv, answering `pr view` with `$STUB_PR_URL` (exit 1 when unset), running `--jq` through real `jq` on `$STUB_JSON`. Cases: `::Unresolved threads listed` proves "Unresolved threads listed" (graphql argv has `owner=o`, `repo=r`, `pr=7`; exact stdout); `::All threads listed` proves "All threads listed"; `::Reply posted from a file` proves "Reply posted from a file" (`api repos/o/r/pulls/7/comments/123/replies -F body=@…/b.md`); `::Threads resolved` proves "Threads resolved"; `::Bad thread input refused` proves "Bad thread input refused" (each exits 2, `$GH_LOG` empty, no `INJECTED`); `::Branch without a pull request refused` proves "Branch without a pull request refused"; `::Thread write dry run` proves "Thread write dry run" (stdout holds the body text). Verify: it fails on the missing script.
- [x] 1.2 Add `skills/comments/scripts/threads.sh` per the design decisions (E1-E3, E6, E7). Verify: `bash skills/comments/scripts/threads.test.sh`.
- [x] 1.3 Wire the suite: `lefthook.yml` both `tests` jobs, CI tests step, root `AGENTS.md` Tests line (E9). Verify: `lefthook run pre-push --all-files`.
- [x] 1.4 Add cases to `tests/guards.test.sh` (E8): a `comments` READONLY entry for `threads.sh list`; `Verdicts shown before any fix` proves "Verdicts shown before any fix"; `Fix folded into its commit` proves "Fix folded into its commit"; `Replies and resolves shown first` proves "Replies and resolves shown first"; add `comments review` to the boundary pairs and `pr-ready comments` to the chaining pairs, which proves "Review thread request goes to comments" with the eval case. Verify: it fails.
- [x] 1.5 Add `evals/comments/prompt.md`, `graders/fires.md`, `graders/not-review.md`, `graders/not-pr-ready.md`, and `evals/pr-ready/graders/not-comments.md`. Verify: `bash tests/guards.test.sh` fails only on the skill.
- [x] 1.6 Add `skills/comments/SKILL.md` (E5, E7). Verify: `bash tests/guards.test.sh`.
- [x] 1.7 `README.md` count, Skill reference and Scripts rows, Tests line, `evals/run.sh` count; `skills/AGENTS.md` row; `plugin.json` 2.6.0 and description, `marketplace.json` list (E9). Verify: `bash skills/map/scripts/check-map.sh`.

## 2. Check
- [x] 2.1 `lefthook run pre-push --all-files`
