# Proposal

Status: done
Issue: diblaze/solo#35

## Why
The release workflow dispatches ci.yml on the release branch so release PR #34 gets the required `check`. That dispatched run passed but did not satisfy the ruleset; the PR went mergeable only after a maintainer approved the parked `pull_request` run. The dispatch step, its `actions: write` permission and ci.yml's `workflow_dispatch:` trigger do nothing useful, so remove them and document the approve step.

## What Changes
- The release workflow no longer starts a CI run. Its job permissions drop `actions: write`.
- ci.yml no longer has a `workflow_dispatch` trigger.
- Releasing: a maintainer approves the parked CI run on the release PR, then merges it.

## Capabilities
### New Capabilities
### Modified Capabilities
- `release-flow`: requirement "Release PR runs the required check" now runs the check once a maintainer approves the parked run.

## Impact
