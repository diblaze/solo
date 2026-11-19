# Proposal

Status: approved
Issue: diblaze/solo#29

## Why
solo has no tags, releases or changelog, and every feat PR hand-bumps `version` in `.claude-plugin/plugin.json` (2.5.0 to 2.9.0 in one day). Claude Code only ships an update to users when that string changes, so the version should come from the conventional commits and every release should leave a tag, a GitHub release and a changelog entry.

## What Changes
- release-please proposes the next version from conventional commits (feat minor; fix, perf, revert or deps patch; `!` major; docs/chore/ci/test/refactor/style/build nothing) in a release PR that bumps `plugin.json`, the release manifest and `CHANGELOG.md`.
- Merging that PR tags `solo--v<version>` (the tag format `claude plugin tag` writes) and publishes a GitHub release with the changelog section.
- The release PR runs the required `check` job, dispatched by the release workflow, so it merges through `merge-pr.sh` like any PR.
- A guard fails when `plugin.json` and the release manifest disagree, so a hand bump in a feature PR fails CI.
- **BREAKING** for contributors: feature PRs no longer touch `version`.
- First release: `solo--v2.9.0` at the current `main` tip, matching `plugin.json`.
- README gets a Releases section; AGENTS.md forbids hand bumps.

## Capabilities
### New Capabilities
- `release-flow`: how the plugin version is derived, where it lives, what a release publishes and how the release PR is checked.
### Modified Capabilities

## Impact
New: `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release.yml`, `CHANGELOG.md` (written by the first release PR). Changed: `.github/workflows/ci.yml` (adds `workflow_dispatch`), `tests/guards.test.sh`, `README.md`, `AGENTS.md`. New action `googleapis/release-please-action` pinned by SHA. Repo setting "Allow GitHub Actions to create and approve pull requests" must be on. No secrets.
