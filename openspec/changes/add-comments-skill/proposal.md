# Proposal

Status: done
Issue: diblaze/solo#23

## Why
After a reviewer, human or bot, comments on a PR, answering and closing the threads is GraphQL and REST calls composed by hand, and nothing stops an agent from fixing every comment unasked, stacking an "address review" commit, or resolving a thread it never handled.

## What Changes
- Add `/solo:comments`: list the open review threads on the branch's PR, triage each against the code, show the verdicts and wait, fix the approved ones, reply, resolve
- One script, `threads.sh`, lists threads, replies to a thread from a file and resolves threads by id; input is checked before `gh` runs and every write takes `--dry-run`
- Fixes fold into the commit that introduced the code and go out through `/solo:pr-ready`, so pushing stays a user yes; replies and resolves are shown with `--dry-run` and posted on a yes
- Eval case for the new skill with zero-call guards against review and pr-ready; README, manifests, lefthook and CI list the skill and its test

## Capabilities
### New Capabilities
- `review-threads`: listing, answering and resolving a pull request's review threads, and the triage gate before any fix
### Modified Capabilities

## Impact
New `skills/comments/SKILL.md`, `skills/comments/scripts/threads.sh`, `threads.test.sh`, `evals/comments/` (prompt, `fires`, `not-review`, `not-pr-ready`), `evals/pr-ready/graders/not-comments.md`. Edits: `tests/guards.test.sh`, `lefthook.yml`, `.github/workflows/ci.yml`, root `AGENTS.md`, `skills/AGENTS.md`, `README.md`, `evals/run.sh` count comment, `.claude-plugin/plugin.json` (2.5.0 to 2.6.0) and `marketplace.json`. Reuses `skills/plan/scripts/common.sh`. No new runtime dependency: list output is shaped with gh's built-in `--jq`; `jq` only in the test harness.
