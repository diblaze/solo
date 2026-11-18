---
name: review
description: Dispatches the read-only reviewer subagent on the current branch diff, then fixes what it finds. Gate 3 of plan → execute → review. Use after execute, or on any diff before it merges. Does not open the PR — use solo:pr-ready (which calls this).
argument-hint: [base branch, default main]
allowed-tools:
  - Bash(${CLAUDE_SKILL_DIR}/scripts/review-md.sh *)
---

# Review

1. Base = `$ARGUMENTS` or `main`, with any `origin/` prefix stripped. `git fetch origin <base>`, then use `origin/<base>` as the ref from here on (no `origin` remote: the local `<base>`). `git diff --stat <ref>...HEAD` — if empty, check `git diff` / `git diff --cached` / `git ls-files --others --exclude-standard` and review the working tree, untracked files included, instead.
2. Rules: `${CLAUDE_SKILL_DIR}/scripts/review-md.sh --base <ref>`. It prints the root `REVIEW.md` and the nearest one above each changed file, read from that ref so the branch cannot loosen the rules it is reviewed by, and nothing when there are none.
3. Dispatch the reviewer agent that the repo's `AGENTS.md`/`CLAUDE.md` or the user's `CLAUDE.md` names for this repo, else `solo:reviewer`, with: the ref as base, the change path (`openspec/changes/<slug>/`) if one exists, the `REVIEW.md` text from step 2 verbatim, and any focus the user gave. One dispatch; do not also review inline.
4. Fix every CRIT and WARN. For each CUT: delete it, or reply in one line why it must stay. `ponytail:` markers named in findings: implement the upgrade or delete the marker.
5. Re-run the change's check (last task group in `tasks.md`, or the repo test command) after fixes.
6. Report: findings count by severity, what was fixed, what was left and why. Do not paste the reviewer output verbatim.
