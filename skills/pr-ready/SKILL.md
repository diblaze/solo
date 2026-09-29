---
name: pr-ready
description: Pre-PR gate — slop pass, reviewer pass, fix every finding, fold fixes into existing commits, then open the PR. Use whenever a branch is about to become a PR, or when a PR was opened without this pass. Does not plan or implement features.
argument-hint: [base branch, default main]
allowed-tools: Bash, Read, Edit, Write, Grep, Glob, Agent, AskUserQuestion
---

# PR ready

Base = `$ARGUMENTS` or `main`. Must be on a non-`main` branch with commits ahead of base.

## 1. Slop pass (own code only)
Scope = `git diff --name-only <base>...HEAD`. One pass per smell, safest first, re-run checks after each:
- dead code, unused exports/imports, debug leftovers
- duplicate logic → the existing helper
- pass-through wrappers, single-impl interfaces, config for constants
- comments restating code; docstrings on the obvious
- tests that assert nothing, `test.skip`, `.only`, placeholder branches
Preserve behavior. No new features. No new deps.

## 2. Review pass
Invoke `/solo:review <base>`. Fix all CRIT/WARN/CUT. No `ponytail:` marker survives: implement the upgrade or delete the marker because the ceiling does not apply.

## 3. Fold, don't stack — atomic, logically grouped
No "cleanup"/"address review" commits. Amend the commit that introduced the code: `git commit --fixup <sha>` then `GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash <base>` (interactive editor is stubbed, so this squashes non-interactively). Then verify: `git log --oneline <base>..HEAD` shows no `fixup!` lines.
Every commit must be one logical change (see `/solo:execute` step 10). A commit that bundles several slices (a whole multi-part feature, unrelated changes), or a history split by layer instead of by slice, is regrouped before the PR opens: `git reset --soft <base>` and re-commit one feature slice per commit in dependency order, then check the final tree equals the old one (`git rev-parse HEAD^{tree}`) and that each commit passes lint + the check on its own. A branch whose single commit really is one logical change → `git commit --amend --no-edit` for fixes.

## 4. Open
`git push -u origin HEAD` then `gh pr create --fill --base <base>` (edit title/body to conventional-commit style if `--fill` is poor). Body must carry `Closes #n` from the plan's `Issue:` line so merge closes the issue. Already-open PR → `git push --force-with-lease` instead. Print the PR URL.
