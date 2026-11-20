# Design
## Context
- E1 `skills/plan/scripts/openspec.sh:6` — `v=1.14.1` — the single pin; lines 9 and 13 use `$v` for both the global check and `npx -y "@fission-ai/openspec@$v"`.
- E2 Other literal pins: `README.md:97` (`Runs OpenSpec 1.14.1`), `README.md:137` (`either OpenSpec 1.14.1 (...) or Node for npx`), `skills/plan/SKILL.md:12` (`They run OpenSpec 1.14.1`), `skills/plan/scripts/AGENTS.md:13`, `skills/AGENTS.md:37`, `skills/plan/scripts/scripts.test.sh:19,370,371` (`echo "${STUB_V:-1.14.1}"`, `npx -y @fission-ai/openspec@1.14.1 validate`). `skills/execute/SKILL.md` and `skills/pr-ready/SKILL.md` carry no version.
- E3 Every subcommand solo calls: `new-change.sh:9` `init --tools none`; `new-change.sh:10` `new change "$slug"`; `validate-change.sh:13` and `fold.sh:26` `validate "$slug" --strict --no-interactive`; `fold.sh:30` `archive "$slug" --yes [--skip-specs]`; `fold.sh:33` `validate --specs --strict --no-interactive`; `openspec.sh:8` `--version`. `set-status.sh` calls no OpenSpec command. No `status`, `update` or `instructions`.
- E4 `openspec/specs/change-scripts/spec.md:97` — "The system SHALL run one exact spec-tool version" — no version number, so no spec delta.
- E5 Empirical, throwaway git repo, `init --tools none` on 1.14.1 vs 2.1.1: identical file tree (`openspec/{changes/archive,specs}/.gitkeep`, `openspec/config.yaml` with `schema: spec-driven`); no `.agents/skills/`. Only the hint text changes (`/opsx:propose` → `/openspec-propose`).
- E6 Empirical, `new change`: identical `.openspec.yaml` (`schema: spec-driven`, `created:`).
- E7 Empirical, `validate --strict`, `archive --yes`, `archive --yes --skip-specs` (with `skip_specs: true`), `validate --specs --strict`: same exit codes (0) and output; archive folder `2026-11-20-add-x` on both. Only diff: the created main spec has a blank line after `## Purpose` (2.1.1 notes: "puts a blank line after `## Purpose`").
- E8 `npx -y @fission-ai/openspec@2.1.1 validate --specs --strict` on this repo — `Totals: 14 passed, 0 failed`.
- E9 Release notes 1.14.2–2.1.1 that touch solo's calls: 1.14.2 strict fails on text archive drops; 1.16.0 strict fails a scenario without GIVEN/WHEN or THEN; 1.16.1 unknown delta sections fail; 2.1.1 strict warns when a MODIFIED requirement passes 500 characters, and archive stops before touching main specs if the archive folder exists. 2.0/2.1 skill moves (`.agents/skills/`, `/opsx:*` removal, global scope) only apply with `--tools <ids>`; solo passes `none`.
- E10 `npm view @fission-ai/openspec@2.1.1 engines` — `{ node: '>=22.20.0' }`; 1.14.1 — `{ node: '>=20.19.0' }`.
- E11 `openspec/specs/release-flow/spec.md:22` — "patch for a `fix`, `perf`, `revert` or `deps` commit". Wrong for `deps`: release-please `src/util/filter-commits.ts` `DEFAULT_CHANGELOG_SECTIONS` (main, 2026-11-20; the action bundles `^17.6.0`) shows only `feat`, `fix`, `perf`, `revert` as visible, and `release-please-config.json` sets no `changelog-sections`.

## Goals / Non-Goals
**Goals:**
- Pin 2.1.1 everywhere E2 lists; scripts and tests agree.

**Non-Goals:**
- Install OpenSpec skills or slash commands into user repos — reopen when solo wants OpenSpec's own agent skills (it has its own).
- Read the pin from one shared file for docs — reopen when a third bump drifts docs.

## Decisions
- Commit type `fix(deps): bump OpenSpec CLI to 2.1.1` → patch release; a bare `deps:` commit would release nothing (E11), so the spec and README are corrected instead of adding `changelog-sections`. solo's commands, flags, layout and archive naming are unchanged (E5-E8), so not breaking for solo users. Lost: `feat` (nothing new for users), `chore` (users run the new binary, so it must release), `!` (see Open Questions).
- Keep `init --tools none` (E3, E5): 2.x writes no skills with it, which is what solo wants.
- README states the Node 22.20.0 floor for the npx path (E10).

## Risks / Trade-offs
- Users on Node 20–22.19 without a global 2.1.1 get an npm `EBADENGINE` warning, and the CLI may then fail at runtime. Node 20 is end-of-life; the standalone OpenSpec binary needs no Node.
- Stricter validation (E9) can fail a change that passed on 1.14.1; this repo's specs pass (E8).

## Open Questions
- Is the Node floor (20.19 → 22.20, E10) breaking enough for a `!` commit and a major release? Resolved 2026-11-20: no, patch.
