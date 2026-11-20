# Proposal

Status: done
Issue: diblaze/solo#32

## Why
solo pins OpenSpec 1.14.1; 2.0.0 and 2.1.1 are out and 1.x gets no fixes. The commands solo calls behave the same on 2.1.1 (design E5-E8), so the bump is cheap now.

## What Changes
- The scripts run OpenSpec 2.1.1 (global binary at that exact version, else `npx -y @fission-ai/openspec@2.1.1`).
- The npx fallback now needs Node 22.20.0 or newer (was 20.19.0); README says so.
- The release docs and the `release-flow` requirement stop saying a `deps` commit releases: release-please's default sections release only `feat`, `fix`, `perf` and `revert`, so this bump is a `fix(deps)` commit.
- New main specs that fold creates get a blank line after `## Purpose` (upstream formatting).

## Capabilities
### New Capabilities
none
### Modified Capabilities
- `release-flow`: "Bump follows the conventional commits" no longer lists `deps` as a releasing type. (`change-scripts` "Spec tool version is pinned" names no version and still holds.)

## Impact
`skills/plan/scripts/openspec.sh`, `skills/plan/scripts/scripts.test.sh`, `skills/plan/SKILL.md`, `skills/plan/scripts/AGENTS.md`, `skills/AGENTS.md`, `README.md`. No config keys, no migrations, no new dependency. Archived changes untouched.
