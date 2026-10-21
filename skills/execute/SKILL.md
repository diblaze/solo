---
name: execute
description: Gate 2 of plan → execute → review. Implements an approved OpenSpec change (openspec/changes/<slug>/) on a branch task by task, runs the check, then chains slop pass → solo:review → atomic conventional commits (one per task group), and marks the change done. Refuses a change whose Status is not approved. Does not open the PR — use solo:pr-ready.
argument-hint: <change slug or path>
---

# Execute

1. Read the change: `proposal.md`, every `specs/**/spec.md`, `design.md`, `tasks.md`. `Status: approved` in `proposal.md` required; otherwise stop and say so. The delta specs are the contract; tasks are the route.
2. Re-check cwd + `git status --short --branch` — right repo, right branch, clean tree or known state. On `main`/`master` → branch first: `git switch -c <type>/<slug>`. Always; gates apply to every non-one-liner.
3. Read the repo's `AGENTS.md` `## Coding standard` if present — runner, package manager, style rules. None → lockfile is law (`uv.lock`→uv, `pnpm-lock.yaml`→pnpm, `yarn.lock`→yarn, `package-lock.json`→npm, `go.mod`→go, `pubspec.yaml`→flutter). Never mix managers.
4. Work `tasks.md` top to bottom, exactly. Tick each box (`- [x]`) the moment its verification passes, not in a batch at the end. A test task comes before the code it proves: write it, watch it fail, then make it pass. Mid-way discovery that changes behavior → update the delta spec and tasks first (`../plan/scripts/validate-change.sh <slug>` still exits 0), then continue; say what changed. A discovery that changes a requirement's meaning → stop and ask.

   Route each group before starting it:

   | work | goes to |
   |---|---|
   | read-only lookup that would flood context (callers across a big repo, log grep) | `solo:explorer` (haiku) |
   | a group that is bounded and fully specified (target paths, scenario or test, verification command), has no judgment calls left, and is not finishable in a handful of tool calls | `solo:implementer`: sonnet by default; `model: "opus"` when the group is heavy (many files, tricky logic) but still fully specified |
   | everything else: ambiguous, cross-cutting, auth/money/data-loss paths, integration; and every verification, tick, slop pass, review dispatch, commit, set-status | main thread (opus), which writes code too |

   Fable only after the user approves it: the request asks to run on Fable, or AskUserQuestion gets a yes; then dispatch `solo:implementer` with `model: "fable"`. No yes, no Fable. One group at a time, in this tree:
   1. Index must be empty (`git diff --cached --quiet`); something staged → stop and ask. Group has a test task → write the test yourself and watch it fail. Record `git status --porcelain`, then `git add -u && git add -- <the group's allowed paths that exist> <test files you wrote for this group> openspec/changes/<slug>/`, so every tracked edit and your own new files are staged and the implementer's edits are the only unstaged changes; untracked files outside those paths (a stray secrets file) stay unstaged.
   2. Dispatch `solo:implementer` with: the group's tasks verbatim, the scenarios they prove, the design E# lines naming the paths, the `## Coding standard`, the verification command, and the allowed-path list.
   3. On return, read `git diff` and `git status --short` and compare them with the recorded status (its edits only; anything new outside the allowed paths is a defect), run the verification yourself, tick, then `git reset -q` to unstage.

   `blocked`, a spec mismatch, or a failed verification → `git reset -q`, then do the group inline; never re-dispatch with a looser spec.
5. Ponytail rules stay on: shortest diff that is correct, reuse over write, no unrequested abstractions. Deliberate ceilings get a `# ponytail: <ceiling>, <upgrade path>` comment. Framework/API questions → Context7, not memory.
6. Run the last task group (the check). Change has none → derive it: Makefile/justfile target → `package.json` `check`/`test` script → `[tool.pytest]` → `go test ./...`; write it back into `tasks.md`. It must pass.
7. Slop pass on your own diff: `/solo:slop` (scope defaults to `git diff --name-only <base>...HEAD`). The check stays green after every pass.
8. Placeholder scan: `rg -n 'TODO|FIXME|NotImplemented|\.only\(|xit\(|xdescribe\(' <diff files>` plus bare skips (`test.skip(` / `pytest.skip(` / `@skip` with no condition-and-reason). Any hit is a blocker. Conditional skips with a reason string (`skipif(cond, reason=...)`, `test.skip(cond, 'why')`) are fine.
9. Invoke `/solo:review <base>`. Fix every CRIT/WARN; delete or justify every CUT. Re-run the check.
10. Commit — **atomic, logically grouped, always.** Never one commit for a whole plan, never one commit per layer. One commit per **feature slice** — the task groups in `tasks.md` are the slices: a capability that works end to end, carrying its backend, UI, tests and the docs for that slice (e.g. "settings + their dialog tab", "the job + its API + dashboard", "webhook follow-up", "undo script"). Order slices by dependency; a refactor or dependency bump nothing user-visible depends on alone may stand as its own commit, otherwise it rides with the slice that needs it. Split a shared file (tests, docs, generated files) across slices so each commit holds only its slice. Every commit must pass lint + the check **on its own** — verify each before reporting, e.g. `git rebase --exec '<check>' <base>`, or a detached worktree looping over `git rev-list --reverse <base>..HEAD` (prefer the loop in a linked worktree: `rebase --exec` exports `GIT_DIR` there, and a test that makes its own repo then writes to yours). A fix found later is folded into the commit that introduced the code (`git commit --fixup <sha>` + autosquash), never stacked. Message: caveman-terse conventional commit, `type(scope): subject` ≤50 chars, imperative, English; body only when the why is not obvious, one line per reason. The change folder itself rides in the first commit. `Refs owner/repo#n` (from the `Issue:` line in `proposal.md`) on the last slice commit; `Closes owner/repo#n` goes on the spec-fold commit `/solo:pr-ready` adds. Scope = the area the commit touches.
11. `../plan/scripts/set-status.sh <slug> done` (path relative to this skill's base directory) — it refuses while any box in `tasks.md` is unticked. An unticked box means not done: finish it or say why it cannot be. Commit the status change into the last slice commit. Report: branch, the commit list (`git log --oneline <base>..HEAD`), per-commit check result, changed files, review findings fixed/left. Next gate is `/solo:pr-ready`, which folds the delta specs into `openspec/specs/`.
