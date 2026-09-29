---
name: execute
description: Gate 2 of plan → execute → review. Implements an approved docs/plans/<slug>.md on a branch, runs the check, then chains slop pass → solo:review → atomic conventional commits (one logical change each), and marks the plan done. Refuses a plan whose Status is not approved. Does not open the PR — use solo:pr-ready.
argument-hint: <plan path or slug>
---

# Execute

1. Read the plan. `Status: approved` required; otherwise stop and say so.
2. Re-check cwd + `git status --short --branch` — right repo, right branch, clean tree or known state. On `main`/`master` → branch first: `git switch -c <type>/<slug>`. Always; gates apply to every non-one-liner.
3. Read the repo's `AGENTS.md` `## Coding standard` if present — runner, package manager, style rules. None → lockfile is law (`uv.lock`→uv, `pnpm-lock.yaml`→pnpm, `yarn.lock`→yarn, `package-lock.json`→npm, `go.mod`→go, `pubspec.yaml`→flutter). Never mix managers.
4. Implement exactly the `## Changes` list. Mid-way discovery that changes the list → update the plan first, then continue; say what changed.
5. Ponytail rules stay on: shortest diff that is correct, reuse over write, no unrequested abstractions. Deliberate ceilings get a `# ponytail: <ceiling>, <upgrade path>` comment. Framework/API questions → Context7, not memory.
6. Run `## Check`. Plan has none → derive it: Makefile/justfile target → `package.json` `check`/`test` script → `[tool.pytest]` → `go test ./...`; write it back into the plan. It must pass.
7. Slop pass on your own diff (`git diff --name-only <base>...HEAD`), safest first, re-run the check after each: dead code, unused imports/exports, debug leftovers, duplicate of an existing helper, pass-through wrappers, single-impl interfaces, config for constants, comments restating code, tests asserting nothing.
8. Placeholder scan: `rg -n 'TODO|FIXME|NotImplemented|\.only\(|xit\(|xdescribe\(' <diff files>` plus bare skips (`test.skip(` / `pytest.skip(` / `@skip` with no condition-and-reason). Any hit is a blocker. Conditional skips with a reason string (`skipif(cond, reason=...)`, `test.skip(cond, 'why')`) are fine.
9. Invoke `/solo:review <base>`. Fix every CRIT/WARN; delete or justify every CUT. Re-run the check.
10. Commit — **atomic, logically grouped, always.** Never one commit for a whole plan, never one commit per layer. One commit per **feature slice**: a capability that works end to end, carrying its backend, UI, tests and the docs for that slice (e.g. "settings + their dialog tab", "the job + its API + dashboard", "webhook follow-up", "undo script"). Order slices by dependency; a refactor or dependency bump nothing user-visible depends on alone may stand as its own commit, otherwise it rides with the slice that needs it. Split a shared file (tests, docs, generated files) across slices so each commit holds only its slice. Every commit must pass lint + the check **on its own** — verify each before reporting, e.g. `git rebase --exec '<check>' <base>`, or a detached worktree looping over `git rev-list --reverse <base>..HEAD`. A fix found later is folded into the commit that introduced the code (`git commit --fixup <sha>` + autosquash), never stacked. Message: caveman-terse conventional commit, `type(scope): subject` ≤50 chars, imperative, English; body only when the why is not obvious, one line per reason. `Closes #n` (from the plan's `Issue:` line; `Refs #n` if the plan is one of several sub-issues) on the **last** commit only. Scope = the area the commit touches.
11. Set `Status: done`. Report: branch, the commit list (`git log --oneline <base>..HEAD`), per-commit check result, changed files, review findings fixed/left. Next gate is `/solo:pr-ready`.
