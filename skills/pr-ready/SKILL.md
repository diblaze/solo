---
name: pr-ready
description: Pre-PR gate — slop pass, reviewer pass, fix every finding, fold fixes into existing commits, fold the change's delta specs into openspec/specs/ and archive it, then open the PR (merged by rebase, never squash). Use whenever a branch is about to become a PR, or when a PR was opened without this pass. Does not plan or implement features.
argument-hint: [base branch, default main]
allowed-tools: Bash, Read, Edit, Write, Grep, Glob, Agent, AskUserQuestion
---

# PR ready

Base = `$ARGUMENTS` or `main`. Must be on a non-`main` branch with commits ahead of base.

## 1. Slop pass (own code only)
Invoke `/solo:slop` — scope = `git diff --name-only <base>...HEAD`. Placeholder branches, bare `test.skip` and `.only` are blockers, not notes.

## 2. Review pass
Invoke `/solo:review <base>`. Fix all CRIT/WARN/CUT. No `ponytail:` marker survives: implement the upgrade or delete the marker because the ceiling does not apply.

## 3. Fold, don't stack — atomic, logically grouped
No "cleanup"/"address review" commits. Amend the commit that introduced the code: `git commit --fixup <sha>` then `GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash <base>` (interactive editor is stubbed, so this squashes non-interactively). Then verify: `git log --oneline <base>..HEAD` shows no `fixup!` lines.
Every commit must be one logical change (see `/solo:execute` step 10). A commit that bundles several slices (a whole multi-part feature, unrelated changes), or a history split by layer instead of by slice, is regrouped before the PR opens: `git reset --soft <base>` and re-commit one feature slice per commit in dependency order, then check the final tree equals the old one (`git rev-parse HEAD^{tree}`) and that each commit passes lint + the check on its own. A branch whose single commit really is one logical change → `git commit --amend --no-edit` for fixes.

## 4. Fold the specs
Branch carries an `openspec/changes/<slug>/` → fold it here, inside the PR, so `openspec/specs/` and the code land together. One command, with a clean tree: `scripts/fold.sh <slug>` (in this skill's base directory). Never run its steps by hand and never merge deltas by hand. It:
1. refuses while `tasks.md` has an unticked box or `Status:` is not `done`;
2. runs strict validation — a `MODIFIED … omits scenario(s)` error means main specs moved under you: copy the named scenarios into the delta, never drop them, then re-run;
3. runs `openspec archive` (`--skip-specs` when `.openspec.yaml` says `skip_specs: true`), which applies ADDED/MODIFIED/REMOVED/RENAMED to `openspec/specs/<capability>/spec.md` and moves the folder to `openspec/changes/archive/YYYY-MM-DD-<slug>/`;
4. strictly validates the living specs;
5. commits the result alone as `docs(spec): fold <slug>` with `Closes owner/repo#n` from the `Issue:` line. This is the one commit that is not a feature slice; nothing else goes in it.
Non-zero exit → fix what it names and re-run; do not work around it. Afterwards check its printed stat: only the capabilities the proposal listed changed under `openspec/specs/`.
No change folder on the branch (one-liner, hotfix) → skip this section and say so in the PR body.

## 5. Open
More than about five slices → stacked PRs instead of one: a branch per group of slices, each based on the previous one (pass the previous branch as `<base>`), so each PR stays reviewable on its own.
Write the body to a file outside the repo (the tree must stay clean). The body lists the requirements added, modified and removed per capability (or says there was no change folder). When the plan names an issue (`/solo:plan #n`, or the `Issue:` line of the archived `proposal.md`), the body also carries `Closes owner/repo#n` so merge closes it; no issue, no `Closes`. Then one command, from the repo root: `scripts/open-pr.sh <base> --title "<type(scope): subject>" --body-file <file>` (in this skill's base directory). It derives the `type:feat|bug|chore` label from the commit subjects, creates the label when the repo lacks it, pushes, opens the PR assigned to `@me`, or force-with-lease pushes and updates the branch's already-open PR, and refuses a body missing the `Closes owner/repo#n` of an archived `proposal.md`. `--dry-run` prints the push and `gh` writes instead of running them. Never run its steps by hand. Print the URL it returns.

## 6. Merge (when the user says merge)
Rebase-merge keeps the slices on the base branch: `gh pr merge <n> --rebase --delete-branch`. Never squash-merge: it flattens the atomic history into one commit. A repo still offering squash gets it switched off once (`gh repo edit <owner/repo> --enable-squash-merge=false`, after asking); rebase and merge commits stay allowed.
