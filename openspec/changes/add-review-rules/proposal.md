# Proposal

Status: done
Issue: diblaze/solo#20

## Why
A repository has no way to tell `/solo:review` what its reviews must flag or skip. Rules read from the working tree would also let a branch loosen the rules it is reviewed by, so they have to come from the base branch.

## What Changes
- Add `review-md.sh`, which prints the root `REVIEW.md` and the nearest `REVIEW.md` above each changed file, read from the base ref
- `/solo:review` runs it before dispatch and passes the rules to the reviewer agent; the reviewer follows them
- The script is a read-only call, pre-approved in the review skill's `allowed-tools`
- README, root `AGENTS.md`, `skills/AGENTS.md`, lefthook, CI and the plugin version list the script and its test

## Capabilities
### New Capabilities
- `review-rules`: which repository review rules a review applies and where they are read from
### Modified Capabilities

## Impact
New `skills/review/scripts/review-md.sh` and `review-md.test.sh`. Edits: `skills/review/SKILL.md`, `agents/reviewer.md`, `tests/guards.test.sh` (read-only allowlist), `lefthook.yml`, `.github/workflows/ci.yml`, root `AGENTS.md`, `skills/AGENTS.md`, `README.md`, `.claude-plugin/plugin.json` (2.5.0 to 2.6.0). No new dependency.
