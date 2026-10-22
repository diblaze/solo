# Proposal

Status: approved
Issue: diblaze/solo#5

## Why
An agent that lands in an unfamiliar directory has to rediscover its purpose, its key files and its test command. Claude Code now loads nested `AGENTS.md` files where a project has no `CLAUDE.md`, so a per-directory map pays off. A manual attempt showed two traps: a file in a plugin's `agents/` breaks strict plugin validation, and the root `## Coding standard` must survive. A skill has to encode both.

## What Changes
- New skill `/solo:map`: writes or refreshes a root `## Map` table plus one `AGENTS.md` per directory that matters, from codebase evidence. The user approves the directory list first. Writes go on a branch as one commit, then `/solo:pr-ready` runs.
- New script `skills/map/scripts/check-map.sh [base-ref]` with its own test. It fails on an `AGENTS.md` in an `agents/`, `commands/` or `output-styles/` folder of a plugin or of `.claude/`. It also fails on a broken relative link or `Parent` comment, and on a root `## Coding standard` that differs from the base ref.
- `solo:implementer` can also be dispatched by `/solo:map`. The `docs` and `standard` descriptions each gain "Does not … — use solo:map".
- Plugin 2.0.1 → 2.1.0. README goes to 15 skills with a skill row, a script row and the tests line. The hooks, CI and the coding standard run the new test suite.

## Capabilities
### New Capabilities
- `directory-map`: which directories get a map file, where files are never written, which content survives a re-run, and how map writes pass the approval and branch gates.
### Modified Capabilities
None.

## Impact
New: `skills/map/SKILL.md`, `skills/map/scripts/check-map.sh`, `skills/map/scripts/check-map.test.sh`. Edited: `agents/implementer.md`, `skills/docs/SKILL.md`, `skills/standard/SKILL.md`, `tests/guards.test.sh`, `README.md`, `AGENTS.md`, `lefthook.yml`, `.github/workflows/ci.yml`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`. No new dependencies; the script uses bash, git and rg.
