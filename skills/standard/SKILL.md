---
name: standard
description: Set or update a repo's coding standard as a `## Coding standard` section in its AGENTS.md — stack, package manager, check command, style and test rules, Context7 library IDs — so humans and agents read the same rules. Detects from the repo, confirms choices with the user, writes once. Use on a new repo, when tooling changes, or when a skill reports "no coding standard". Does not enforce the standard on a diff — use solo:review.
argument-hint: [repo root, default cwd]
---

# Standard

The repo's tooling config is the standard. This section only records what the tools cannot enforce and what an agent cannot infer in one read.

## 1. Detect (read-only)
- Package manager: lockfile is law — `uv.lock`, `pnpm-lock.yaml`, `yarn.lock`, `package-lock.json`, `bun.lockb`, `go.mod`, `pubspec.yaml`, `Cargo.lock`. Two lockfiles → that is a finding, ask which stays.
- Framework + version: `package.json` deps / `pyproject.toml` / `go.mod` / `pubspec.yaml`. Resolve each to a Context7 library ID (`resolve-library-id`) — the ID goes in the section so later sessions query the right docs without guessing.
- Check command: Makefile/justfile targets → `package.json` `check`/`test`/`lint` scripts → `[tool.pytest.ini_options]`, `[tool.ruff]` → `go test ./...`. CI workflow (`.github/workflows/*.yml`) is the authority on what "green" means — read it.
- Formatter/linter config present: prettier, eslint/biome, ruff, gofmt, dart format. Present → "config is law, do not restate its rules". Absent → propose the framework default, one tool, no debate.
- Existing patterns: sample 3-5 source files and 3 tests. Naming (`test_*.py`, `*.spec.ts`, `*_test.go`), test style (table tests? RTL? fixtures?), async usage, comment density, language of comments/docs.
- Existing `AGENTS.md`/`CLAUDE.md`: read fully. Rules already there are kept, not duplicated.
Big repo → one `solo:explorer` dispatch per bullet, in parallel.

## 2. Confirm
One AskUserQuestion round, at most 4 questions, only where detection was ambiguous or the choice is a real preference: skip policy, test placement, strictness (typecheck in check?), language of docs. Everything detectable is stated, not asked.

## 3. Write
Insert or replace exactly one section in `AGENTS.md` (create the file with just this section if missing; `CLAUDE.md` gets a one-line `@AGENTS.md` if it exists and does not already include it):

```markdown
## Coding standard
- Stack: <framework> <version> — Context7 `<id>`; <secondary> — Context7 `<id>`
- Package manager: <pm> (lockfile `<file>`). Never another.
- Check: `<one command>` — must be green before commit. CI: `<workflow file>`.
- Format/lint: `<tool>` config in `<path>` is law. Run `<fix command>` before commit.
- Tests: `<runner>`, files `<pattern>`, next to source | in `tests/`. Public surface only; stubs at trust boundaries only. Conditional skips need a reason string; bare skip/`.only` is a blocker.
- Style: <≤5 rules the tools cannot enforce — e.g. signals not services for state, table tests, no default exports, errors wrapped with context>
- Language: code + commits English; docs <en|sv>.
- Tracking: GitHub Issues. Labels `type:bug|feat|chore` (issue types are org-only). Deps via `--blocked-by`. Ready queue: `gh issue list --search '-is:blocked is:open'`. Commits close with `Closes #n`.
- Don't: <≤3 repo-specific traps, each one line>
```
≤ 20 lines. Every line must be checkable by reading the repo or running the command; opinions without a check go in a `# ponytail:` comment or nowhere.

## 4. Verify
Run the Check and the fix command as written. A command you could not run → `Unverified: <cmd>, because <why>` inline in the section. Show the diff of AGENTS.md; commit only if asked (`docs(agents): add coding standard`).
