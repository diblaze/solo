---
name: map
description: Write or refresh a per-directory AGENTS.md map from codebase evidence — a root `## Map` table plus one AGENTS.md (Purpose, Key files, For AI agents, Dependencies) per directory that carries weight. Re-runnable; keeps hand-written lines. Use on a new or inherited repo, or when the layout moved. Does not set the coding standard — use solo:standard. Does not write README, feature or API docs — use solo:docs.
argument-hint: [repo root, default cwd]
---

# Map

## 1. Preflight
Repo root = `$ARGUMENTS` or cwd. Re-check `git status --short --branch`.
Any of `CLAUDE.md`, `.claude/CLAUDE.md`, `CLAUDE.local.md` at the root → Claude Code then loads nested AGENTS.md only with `instructionFiles: claude-md-and-agents-md`, and the map loads only once none of them remain. Name every one found, and in step 4 ask whether to delete those CLAUDE.md files; delete each only on a yes (`git rm` when tracked, `rm` when not). Never change their content or the option.

## 2. Candidates
The universe is `git ls-files`, so `.git`, ignored builds and venvs drop out. A directory qualifies with 3 or more tracked files directly in it, or 2 or more subdirectories holding tracked files; anything with fewer than 3 files and fewer than 2 such subdirectories is skipped.
Always skip, with the reason: hidden (`.`-prefixed), vendored (`vendor/`, `third_party/`, tracked `node_modules/`), generated (`dist/`, `build/`, files whose header says generated), fixture (`fixtures/`, `testdata/`, `__snapshots__/`) and `openspec/` (the spec tool owns it).
Never map `agents/`, `commands/` or `output-styles/`, or anything below them, under a plugin root (a directory holding `.claude-plugin/plugin.json`, or custom paths that `plugin.json` declares) or under `.claude/`: Claude Code reads every markdown file there as a definition that must carry frontmatter, and `claude plugin validate --strict` fails. `check-map.sh` refuses them too.
Top-level directories that get no file still get an unlinked row in the root Map.

## 3. Evidence
Small repo (a handful of reads) → read inline. Otherwise one `solo:explorer` per top-level directory, in parallel: tracked files, one purpose line each as `path:line`, the test command, internal dependencies. Existing AGENTS.md files are read in full first.

## 4. Approve
AskUserQuestion with three lists: mapped, skipped (with reason) and orphaned — existing AGENTS.md files whose directory no longer qualifies, each shown with its hand-written lines. Nothing is written before the user says yes; orphans are removed with `git rm`, Map row included, only on yes.
On yes, on `main`/`master`: `git switch -c docs/agents-map` (or `git switch docs/agents-map` when it already exists) before the first file is written.

## 5. Write
Nested file: `<!-- Parent: <rel>/AGENTS.md -->` pointing at the nearest mapped ancestor, `# <dir>/`, `## Purpose` (one paragraph), `## Key files` (`| File | Purpose |`, every tracked file directly in the directory, up to 15, then `+N more`), `## For AI agents` (the test command plus up to 3 rules, each with `path:line`), `## Dependencies` (internal directories, external tools). Root: only `## Map` (`| Directory | Purpose |`), replaced in place or appended at the end; every other root line stays, and `## Coding standard` byte for byte.
Re-run: table rows are keyed by their first-column path — a row stays with its cell while the path exists, new paths get rows, gone paths lose them. Every other line is kept unless the code proves it false, citing `path:line`. Files carry no timestamps, so an unchanged tree re-run leaves no diff.
Up to a handful of files → write them yourself. More → depth-ordered batches to `solo:implementer` with the evidence, this format, the batch's AGENTS.md paths as allowed paths and the absolute path of `scripts/check-map.sh` as the verification; record `git status --porcelain` first and compare after, as in `/solo:execute` step 4.

## 6. Verify and commit
Run `scripts/check-map.sh` (in this skill's base directory); in a plugin repo also `claude plugin validate --strict .`. Both must pass.
Stage only the map: `git add -- <each AGENTS.md written>` (`git rm` already staged every removal). Commit `docs(agents): map directories` (first run) or `docs(agents): refresh map`.

## Done
Report: mapped, skipped and removed directories, the `CLAUDE.md` loading note if it applies, the check output. Next gate: `/solo:pr-ready`.
