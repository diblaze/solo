# Design
## Context
- E1 `.claude-plugin/plugin.json:3` — `"version": "2.9.0",` — the only version string today.
- E2 `git log -L '/"version"/,+1:.claude-plugin/plugin.json'` — bumps in `499c7a3`, `bbb4a7c`, `c9017f8`, `f19d6ee` (2.5.0 to 2.9.0), each inside a feat commit; `git tag` prints nothing. No skill text asks for a bump: `rg -n -i 'bump|plugin\.json' skills agents` hits only `skills/plan/scripts/AGENTS.md:24` (OpenSpec pin) and `skills/map/` (manifest detection).
- E3 `.claude-plugin/marketplace.json:7-8` — `"name": "solo",` / `"source": "./",` — no `version`; relative-path source.
- E4 `.github/workflows/ci.yml:3-7` — `push: branches: [main]` / `pull_request: branches: [main]` — no `workflow_dispatch`; `:9-10` `permissions: contents: read`; `:17` job `check:`; `:21` `actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1` — SHA pins; `:49-52` `plugin validate --strict` at 2.1.306.
- E5 `gh api repos/diblaze/solo/rulesets/25596193` — `"required_status_checks":[{"context":"check",…}]` on the default branch; `gh api repos/diblaze/solo/actions/permissions/workflow` — `"can_approve_pull_request_reviews":false` at planning time; true since task 3.1.
- E6 `openspec/specs/pr-merge/spec.md:40` — refuses a PR "whose merge state is blocked, dirty, behind or unknown"; a release PR without a `check` run is blocked, so `merge-pr.sh` refuses it.
- E7 `tests/guards.test.sh:4-11` — `set -euo pipefail` … `has()`; static repo checks run by CI (`ci.yml:39`) and lefthook pre-push (`lefthook.yml:18`).
- E8 https://code.claude.com/docs/en/plugins/loading.md "How Claude Code computes the version" (fetched 2026-11-19) — "The `version` field in the plugin's manifest comes first", then the marketplace entry, else the commit SHA; a pinned version keeps users on the cache "until its author changes the string".
- E9 https://code.claude.com/docs/en/plugins/host-marketplace.md "Release a new version" (2026-11-19) — "Don't set `version` in both `plugin.json` and the marketplace entry"; `claude plugin validate` reports the mismatch.
- E10 https://code.claude.com/docs/en/plugins/dependencies.md "Create a release tag" (2026-11-19) — "Tag each release as `<plugin-name>--v<version>`"; for a relative-path source "the marketplace maintainer creates the tags"; plain `git tag` is fine if versions agree. `claude plugin tag --help` (local 2.1.328) — "Create a {name}--v{version} git tag".
- E11 https://code.claude.com/docs/en/plugins/publish.md "Prepare your plugin for release" (2026-11-19) — "either increment `version` on every release, or omit it"; keep `--strict` in CI when `version` is set.
- E12 Practice (GitHub API, 2026-11-19): anthropics/claude-plugins-official and anthropics/skills have no tags or releases (the official marketplace pins external plugins by SHA, `bump-plugin-shas.yml`); obra/superpowers tags `v7.0.2` with `RELEASE-NOTES.md`; anthropics/claude-code tags `v2.1.328` with `CHANGELOG.md`; EveryInc/compound-engineering-plugin runs release-please (`release-type: simple`, `extra-files` json `$.version`, tags `compound-engineering-v3.38.2`, `GITHUB_TOKEN`).
- E13 anthropics/claude-plugins-official `.github/workflows/bump-plugin-shas.yml` header — "PRs opened with GITHUB_TOKEN don't trigger on:pull_request workflows … workflow_dispatch is exempt from that recursion guard, so we dispatch all three ourselves … Each check run lands on the branch HEAD".
- E14 release-please `docs/manifest-releaser.md` and `schemas/config.json` (main, 2026-11-19) — `bootstrap-sha` bounds the first changelog; manifest entry sets the current version; `tag-separator`, `include-component-in-tag`, `extra-files` `{type: json, jsonpath}`. `src/manifest.ts:556-612` — a release tag is parsed with a one-character separator (`solo--v2.9.0` parses as component `solo-`, logged "not configured"), then `backfillReleasesFromTags` finds it by exact name `solo--v2.9.0`. `src/strategies/base.ts:333` — "No user facing commits found … skipping".
- E15 release-please-action README (2026-11-19) — needs `contents: write`, `issues: write`, `pull-requests: write` and "Allow GitHub Actions to create and approve pull requests"; output `pr` is a PullRequest JSON with `headBranchName`. v5.0.0 (2026-04-22) is commit `45996ed1f6d02564a971a2fa1b5860e934307cf7`.

## Goals / Non-Goals
**Goals:**
- One version: `plugin.json` (what Claude Code reads, E8), mirrored by the release manifest release-please needs, guarded equal (E7).
- Bump from commits, release PR, `solo--v<version>` tag, GitHub release, `CHANGELOG.md`.
- Release PR passes the required `check` and merges via `merge-pr.sh` (E5, E6).

**Non-Goals:**
- Changelog for history before 2.9.0 — reopen when a user asks for it.
- Marketplace `ref`/`sha` pin or release channels (E3 stays `./`) — reopen when a stable channel is wanted.
- Release assets (`.zip` for `--plugin-url`) — reopen when someone installs without a marketplace.
- Running `claude plugin tag` in CI — release-please writes the same tag name (E10, E14).

## Decisions
- release-please, `release-type: simple`, `package-name: solo`, `extra-files` json `$.version` on `.claude-plugin/plugin.json`, root config and manifest files (no path inputs) — fits rebase-merged conventional commits as-is; semantic-release publishes on every push with no review PR, changesets needs a changeset file per PR. E12, E14.
- Tag `solo--v<version>` (`include-component-in-tag: true`, `tag-separator: "--"`) — the Claude Code format that dependency ranges resolve against; `v<version>` lost because it is not what `claude plugin tag` writes. Cost: one release-please warning per run (E14).
- `bootstrap-sha` = `9521ccbfad93ca7d5ce3a9515d0caa29ed473a18` (current `main` tip, plugin.json `2.9.0`; use the branch's merge-base if `main` moved) and manifest `{".": "2.9.0"}`; release `solo--v2.9.0` created at that SHA — the first release-please run on the merge push cannot sweep all history even if the tag is not there yet. E14.
- Version stays out of `marketplace.json`; `plugin validate --strict` already fails a mismatch (E9). The guard only compares plugin.json with the release manifest.
- `GITHUB_TOKEN`, no PAT: the release job runs `gh workflow run ci.yml --ref <headBranchName>` after release-please, and `ci.yml` gains `workflow_dispatch` — the pattern the official marketplace uses (E13). PAT/App token lost: a long-lived secret on a public repo for one check run. Branch name passed via `env`, never inlined in `run`.
- Permissions: workflow `permissions: {}`; release job `contents: write`, `pull-requests: write`, `issues: write` (labels), `actions: write` (dispatch). E15.
- Merging the release PR uses `/solo:pr-ready` step 6 unchanged; no skill text changes (E2).

## Risks / Trade-offs
- Turning on "Allow GitHub Actions to create and approve pull requests" also lets a workflow approve PRs; the ruleset requires no approvals (E5), so the gain for an attacker is nil today.
- The `--` separator relies on tag backfill (E14); a release-please change there would make it re-propose from `bootstrap-sha`. The guard pins the config; the first real release proves it.
- Tags and releases made with `GITHUB_TOKEN` trigger no workflows; nothing listens for them.
- A contributor who bumps both files by hand passes the guard; release-please then proposes from that number.

## Open Questions
- None. Resolved 2026-11-19: "Allow GitHub Actions to create and approve pull requests" is on (`can_approve_pull_request_reviews: true`); no PAT.
