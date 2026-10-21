# Proposal

Status: done
Issue: diblaze/solo#3

## Why
The repo is public and has no CI, no hooks and no dependency updates: a broken script, a leaked secret or a private hostname reaches `main` unnoticed. shellcheck already reports 8 warnings and 1 error today, so the scripts must pass it before a gate can enforce it.

## What Changes
- shellcheck-clean scripts at warning severity (no behavior change)
- `.gitleaks.toml`: default secret rules plus two generic privacy rules (private/CGNAT IPv4, absolute home-directory paths); no names, domains or hosts in it
- `lefthook.yml`: pre-commit runs shellcheck on staged `*.sh`, the three test suites when scripts, skills or agents change, gitleaks on staged changes; pre-push runs shellcheck, the suites, gitleaks over history
- `.github/workflows/ci.yml` on push/PR to `main`: actionlint, shellcheck, the three suites, gitleaks over full history, plugin manifest validation; SHA/digest-pinned, `contents: read`, concurrency cancel
- `.github/dependabot.yml`: weekly github-actions updates, `chore(deps)` prefix
- README `## Contributing` and an `AGENTS.md` `## Coding standard`
- Post-merge, manual, on the owner's yes: a separate ruleset requiring the CI check on `main`

## Capabilities
### New Capabilities
None: repository tooling only; no plugin behavior changes (`skip_specs: true`).
### Modified Capabilities
None.

## Impact
New: `.gitleaks.toml`, `lefthook.yml`, `.github/workflows/ci.yml`, `.github/dependabot.yml`, `AGENTS.md`. Edited: `skills/plan/scripts/common.sh`, `skills/plan/scripts/scripts.test.sh`, `README.md`. Contributor tools: lefthook, gitleaks, shellcheck, rg. No plugin version bump: installed plugin behavior is unchanged.
