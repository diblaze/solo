# Proposal

Status: done
Issue: diblaze/solo#10

## Why
Four skill steps still have the agent hand-type `gh`/`git` write sequences (issue creation, issue reading with collaborator checks, PR merge, per-commit check), so each run can differ; a stacked merge already had to be repaired by hand. `fold.sh` and `open-pr.sh` also refuse on unrelated untracked files, forcing scratch worktrees.

## What Changes
- Add create-issue.sh: on approval, create the change's tracking issue and set the change approved
- Add `read-issue.sh <n|url>`: prints the issue JSON plus one `collaborator|outsider <login>` line per author
- Add `merge-pr.sh <n> [--dry-run]`: switches squash off, rebase-merges, retargets stacked child PRs, deletes the branch, fast-forwards the local base
- Add `verify-commits.sh <base> -- <check…>`: runs the check on every commit in a throwaway worktree, names the first failing commit
- `open-pr.sh` ignores untracked files; `fold.sh` ignores untracked files outside `openspec/`
- plan, investigate, execute, pr-ready and ship skills call these scripts instead of describing the commands

## Capabilities
### New Capabilities
- `issue-tracking`: reading an issue with each author's standing, and creating the tracking issue of an approved change
- `pr-merge`: merging a pull request by rebase, stacked children first, with a dry run
- `commit-check`: checking each branch commit on its own outside the caller's tree
### Modified Capabilities
- `pr-open`: "Preconditions are checked before any remote action" — only tracked changes make the tree dirty
- `change-scripts`: adds "Fold needs a clean tree" (tracked changes and untracked `openspec/` files refuse)

## Impact
New `skills/plan/scripts/{create-issue,read-issue,verify-commits}.sh`, `skills/pr-ready/scripts/merge-pr.sh`; `common.sh` gains `write`, `ensure_label`, `tracked_clean`; edits to `open-pr.sh`, `fold.sh`, three test files (`scripts.test.sh`, `open-pr.test.sh`, `guards.test.sh`), five `SKILL.md`, two scripts `AGENTS.md`, `README.md`. Needs gh >= 2.100. No new dependency, no new test suite.
