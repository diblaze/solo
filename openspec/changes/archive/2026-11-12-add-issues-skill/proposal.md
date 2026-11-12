# Proposal

Status: done
Issue: diblaze/solo#12

## Why
Outside the tracking issue that approval creates, every issue write (edit, comment, close, dependencies, milestones, issue type) is a `gh` command the agent composes by hand, so runs differ and each one costs tokens. With a script per operation the same call gives the same `gh` command every time, and a write can be dry-run before it reaches the forge.

## What Changes
- Add `/solo:issues` skill for the GitHub issue lifecycle
- One script, `issue.sh`, creates, edits, comments on, closes, reopens and lists issues and manages milestones
- Every issue carries exactly one type, `feat`, `bug` or `chore`, set as GitHub's issue type (`Feature`, `Bug`, `Task`) and not as a label
- The tracking issue `create-issue.sh` opens on approval gets the issue type from the slug prefix; `type:*` labels stay on PRs only
- `list --ready` prints unblocked open issues, filterable by type and milestone, one compact line each
- Every write takes `--dry-run`; bad input exits 2 before any forge call
- README, skill map, plugin manifests, lefthook and CI list the new skill and its test

## Capabilities
### New Capabilities
### Modified Capabilities
- `issue-tracking`: adds ad-hoc issue lifecycle requirements (create, issue type, edit, dependencies, comment, close/reopen, list, milestones, input refusal, dry run); the tracking issue's type label becomes an issue type

## Impact
New `skills/issues/SKILL.md`, `skills/issues/scripts/issue.sh`, `skills/issues/scripts/issue.test.sh`. Edits: `lefthook.yml`, `.github/workflows/ci.yml` (test line, `jq` install), root `AGENTS.md` (Tests line), `skills/AGENTS.md`, `README.md`, `.claude-plugin/plugin.json` (2.1.1 to 2.2.0), `.claude-plugin/marketplace.json`. Reuses `skills/plan/scripts/common.sh`. Needs gh >= 2.100 (blocked-by flags). No new runtime dependency; `jq` only in the test harness.
