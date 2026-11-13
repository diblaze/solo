# Proposal

Status: done
Issue: diblaze/solo#14

## Why
Skills tell the model to work out script paths from "the base directory shown when the skill loads" or `../plan/scripts/…`, no skill pre-approves anything, so every read-only script call can prompt, and three descriptions render `<slug>` as `&lt;slug&gt;` or speak to "you". Claude Code now expands `${CLAUDE_SKILL_DIR}` in skill text and in `allowed-tools`, so both can be exact.

## What Changes
- Every script a SKILL.md runs is named by `${CLAUDE_SKILL_DIR}/scripts/…` (own) or `${CLAUDE_SKILL_DIR}/../plan/scripts/…` (shared); no "base directory" wording left
- plan, investigate, execute, issues and map pre-approve their read-only script calls through `allowed-tools`; state-changing and outward scripts keep their prompt
- execute and pr-ready show `git status --short --branch` at load through dynamic injection, with a matching `allowed-tools` entry; they still load outside a work tree and show git's error
- plan, execute, review, ship, docs and the planner agent get descriptions with `[slug]` placeholders, third person, use case first
- `tests/guards.test.sh` fails when any of the above reverts; its two "no `allowed-tools`" checks become "no outward script pre-approved"
- Plugin version 2.2.0 to 2.3.0

## Capabilities
### New Capabilities
- `skill-loading`: how a skill names its scripts, which of its calls run without a prompt, what state it shows at load, and how its description reads in the listing
### Modified Capabilities

## Impact
`skills/{plan,execute,ship,investigate,issues,map,pr-ready,review,docs}/SKILL.md`, `agents/planner.md`, `tests/guards.test.sh`, `skills/AGENTS.md`, `SECURITY.md`, `.claude-plugin/plugin.json`. No script, dependency or config key changes. Needs a Claude Code that expands `${CLAUDE_SKILL_DIR}` (installed 2.1.323; CI validates with 2.1.306).
