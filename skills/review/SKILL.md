---
name: review
description: Gate 3 of plan → execute → review. Dispatches the read-only reviewer subagent on the current branch diff, then fixes what it finds. Use after execute, or on any diff before it merges. Does not open the PR — use solo:pr-ready (which calls this).
argument-hint: [base branch, default main]
---

# Review

1. Base = `$ARGUMENTS` or `main`. `git diff --stat <base>...HEAD` — if empty, check `git diff` / `git diff --cached` / `git ls-files --others --exclude-standard` and review the working tree, untracked files included, instead.
2. Dispatch the reviewer agent that the repo's `AGENTS.md`/`CLAUDE.md` or the user's `CLAUDE.md` names for this repo, else `solo:reviewer`, with: base branch, the change path (`openspec/changes/<slug>/`) if one exists, and any focus the user gave. One dispatch; do not also review inline.
3. Fix every CRIT and WARN. For each CUT: delete it, or reply in one line why it must stay. `ponytail:` markers named in findings: implement the upgrade or delete the marker.
4. Re-run the change's check (last task group in `tasks.md`, or the repo test command) after fixes.
5. Report: findings count by severity, what was fixed, what was left and why. Do not paste the reviewer output verbatim.
