# Proposal

Status: done
Issue: diblaze/solo#21

## Why
When the approach is still open, the only paths today are `/solo:research`, which is built around external sources, and `/solo:plan`, which commits to one approach. Nothing lays out the materially different ways to solve a problem in this codebase, with their cost and failure mode, before anyone picks.

## What Changes
- Add `/solo:brainstorm`: three to five grounded options, each with cost, where it breaks first and when it is right, one of them the do-nothing option, ending on a recommendation and the open questions
- It writes no code and no files and hands the chosen option to `/solo:plan`
- `/solo:plan` and `/solo:research` name it in their "does not" lines, and README lists it
- Eval case for the new skill, with zero-call guards against plan and research, and brainstorm guards in the plan and research cases

## Capabilities
### New Capabilities
- `option-brainstorm`: the options landscape a brainstorm produces and what it never does
### Modified Capabilities

## Impact
New `skills/brainstorm/SKILL.md`, `evals/brainstorm/` (prompt, `fires`, `not-plan`, `not-research`), `evals/plan/graders/not-brainstorm.md`, `evals/research/graders/not-brainstorm.md`. Edits: `skills/plan/SKILL.md` and `skills/research/SKILL.md` descriptions, `tests/guards.test.sh` (boundary pairs, brainstorm text cases), `README.md` (count, Skill reference), `skills/AGENTS.md`, `.claude-plugin/plugin.json` (2.5.0 to 2.6.0) and `marketplace.json`.
