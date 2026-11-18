# Proposal

Status: done
Issue: diblaze/solo#22

## Why
Docs, ADRs and PR bodies that solo writes carry the usual model tells: contrasts nobody asked for, one-line closers, dashes, inflated claims. Nothing in the plugin catches them before a person reads the text.

## What Changes
- Add `/solo:writer`: rewrites or reviews prose people read so it sounds like a person wrote it, keeping every fact; review mode lists the tells and changes nothing
- It leaves code, code comments, agent instruction files and commit messages alone, and the final text holds no em or en dash
- `/solo:docs`, `/solo:adr` and the PR body step of `/solo:pr-ready` run their prose through it in embedded mode, which keeps the caller's format
- A `NOTICE` file credits the MIT-licensed pattern catalog the skill derives from
- Eval case for the new skill, with zero-call guards against the skills that call it; README and manifests list it

## Capabilities
### New Capabilities
- `prose-pass`: how prose for people is rewritten or reviewed, what it never touches, and which skills pass their prose through it
### Modified Capabilities

## Impact
New `skills/writer/SKILL.md`, `skills/writer/references/patterns.md`, `NOTICE`, `evals/writer/` (prompt, `fires`, `not-docs`, `not-adr`, `not-pr-ready`). Edits: `skills/docs/SKILL.md`, `skills/adr/SKILL.md`, `skills/pr-ready/SKILL.md` step 5, `tests/guards.test.sh`, `README.md` (count, Skill reference, License), `evals/run.sh` count comment, `skills/AGENTS.md`, `.claude-plugin/plugin.json` (2.5.0 to 2.6.0) and `marketplace.json`.
