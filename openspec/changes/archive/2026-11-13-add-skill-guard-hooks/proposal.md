# Proposal

Status: done
Issue: diblaze/solo#16

## Why
"Never commit on main/master" lives only as prose in `/solo:execute` step 2, so a run that skips it lands the change's first commit on main. A hook from a skill stays registered for the rest of the session and in every repository, so the guard has to block only that commit and leave everything else alone, including repositories that commit straight to main.

## What Changes
- `/solo:execute` registers a PreToolUse hook. It refuses a `git commit` on main or master when the commit carries the folder of a change whose Status is approved.
- Every other commit, command, branch and repository passes untouched. If the guard itself faults, the command runs anyway.
- New offline test suite for the guard, run by lefthook, CI and the documented Tests line
- The placeholder scan, the "PRs only through open-pr.sh" rule and the "never squash-merge" rule stay as they are, with no hooks (reasons in design.md)

## Capabilities
### New Capabilities
### Modified Capabilities
- `workflow-guards`: adds two requirements. The first refuses an approved change's commit on main or master. The second keeps the commit guard inert for all other work.

## Impact
New `skills/execute/scripts/commit-guard.sh` and `skills/execute/scripts/commit-guard.test.sh`. Edits: `skills/execute/SKILL.md` (frontmatter `hooks:`, one sentence in step 2), `tests/guards.test.sh`, `lefthook.yml`, `.github/workflows/ci.yml`, root `AGENTS.md` (Tests line), `README.md` (Scripts row, Tests line), `.claude-plugin/plugin.json` (2.3.0 to 2.5.0 (after `add-plugin-eval-suite` takes 2.4.0)). Runtime needs `jq`, `rg` and `git` in the hook's environment; if one is missing, the guard does nothing. No migration.
Blocked by `modernize-skill-frontmatter`: that change rewrites the same `skills/execute/SKILL.md` frontmatter and its script paths to `${CLAUDE_SKILL_DIR}`. Rebase this change onto it before executing. The version bump then takes the next minor after that change's version.
