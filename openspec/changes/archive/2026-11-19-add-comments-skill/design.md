# Design
## Context
- E1 `skills/issues/scripts/issue.sh:1-3` — "One call per GitHub issue operation, so nobody composes gh by hand. … Input is checked before gh runs (exit 2); --dry-run prints each write instead of making it." — the script shape to copy; `:38-41` `--dry-run` last only.
- E2 `skills/plan/scripts/common.sh:19` — "`write() { if [ -n "${dry:-}" ]; then printf '%q ' "$@"; echo; else "$@" >/dev/null; fi; }`" — the dry-run helper.
- E3 `skills/plan/scripts/create-issue.sh:41` — URL regex `^https://[^/]+/([^/]+/[^/]+)/issues/([0-9]+)$` — parse the PR URL the same way, so a fork PR is read from its base repository.
- E4 `skills/issues/scripts/issue.test.sh:12-30` — stub `gh` logging argv and running `--jq` through real `jq` on `$STUB_JSON` — the harness to copy.
- E5 `skills/pr-ready/SKILL.md` section 3 — "No "cleanup"/"address review" commits. Amend the commit that introduced the code: `git commit --fixup <sha>`" — the fold rule fixes follow; section 5 — `open-pr.sh … --dry-run`, AskUserQuestion, "only on yes" — the only push path.
- E6 `gh api --help` (2.103) — "`-F` … if the value starts with `@`, the rest of the value is interpreted as a filename to read the value from"; "For GraphQL requests, all fields other than `query` and `operationName` are interpreted as GraphQL variables."
- E7 REST `pulls/{n}/comments` has no resolved state or thread node id; GraphQL `reviewThreads` has `id`, `isResolved`, `isOutdated`, `path`, `line`, and `resolveReviewThread(input:{threadId})` resolves one.
- E8 `tests/guards.test.sh` "Chaining skill without a guard refused" and the READONLY map — comments invokes pr-ready, so the pr-ready case refuses comments; `list` is read-only and pre-approved.
- E9 `README.md:7` count, `README.md:32-49` Skill reference, `README.md:92-107` Scripts, `README.md:109` Tests, `evals/run.sh:3`; `AGENTS.md:6`; `skills/AGENTS.md:7-24`; `lefthook.yml:9,18`; `.github/workflows/ci.yml` tests step; `.claude-plugin/plugin.json:3-4`, `marketplace.json:10`.

## Goals / Non-Goals
**Goals:**
- One script call per thread operation, checked before `gh`, `--dry-run` on every write, and a skill that never fixes, pushes, replies or resolves without the user's say.

**Non-Goals:**
- Inline reply text — bodies come from a file, as in `issue.sh`; reopen when a caller cannot write a file.
- More than 100 threads or 20 comments per thread — the list says when it truncates; reopen on a PR that hits it.
- Posting new review comments — that is a review, not an answer.
- A prose pass on replies — reopen when a writer skill is on the same branch.

## Decisions
- One `threads.sh <list|reply|resolve>` with one test file, like `issue.sh` (E1).
- The PR's URL gives owner, repo and number (E3); `{owner}`/`{repo}` placeholders would name the fork's repository for a fork PR.
- List output is shaped by gh's built-in `--jq`, so the script needs no `jq` or `python3` at run time; the harness runs the expression through real `jq` (E4).
- Reply body sent with `-F body=@<file>` (E6): no argv size limit, and the dry run prints the path, not the text.
- One commit slice: `tests/guards.test.sh` requires a trigger case for every `skills/` folder, so the script cannot land before the skill (E8).
- The skill makes `--fixup` commits and leaves folding them to `/solo:pr-ready`, which also runs slop and review over the whole branch and asks for the push (E5).
- A reply dry run prints the body file's text, so the yes covers the words that get posted.

## Risks / Trade-offs
- The rebase rewrites shas, so a reply names the sha after the push, never before it.
- A bot reviewer re-reviews after each push; the loop runs again on the new unresolved threads only.

## Open Questions
