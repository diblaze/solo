# Design
## Context
- E1 `skills/plan/SKILL.md:11` — "`gh issue view n --json url,title,body,author,comments,labels,parent,blockedBy,subIssues`. For each author … run `gh api repos/<owner>/<repo>/collaborators/<login> --silent`" — read sequence typed by hand.
- E2 `skills/investigate/SKILL.md:33` — "`gh issue view n --json title,body,author,comments` … (`gh api repos/<owner>/<repo>/collaborators/<login> --silent` fails)" — second caller of the same read.
- E3 `skills/plan/SKILL.md:16` — "`gh issue create --title "<first What Changes line>" --body "Change: openspec/changes/<slug>/" --label type:<bug|feat|chore>` then `scripts/set-status.sh <slug> approved <owner/repo#n>`" — write typed by hand, no assignee, no label creation.
- E4 `skills/ship/SKILL.md:14` — "On approve set `Status: approved`" — ship's own gate skips issue creation entirely.
- E5 `skills/plan/SKILL.md:12` — "verb first: `add-`, `fix-`, `remove-`"; `skills/investigate/SKILL.md:33` — "`openspec/changes/fix-<slug>/`" — slug prefix already encodes the kind.
- E6 `skills/pr-ready/SKILL.md:36-37` — "`gh pr merge <n> --rebase --delete-branch` … (`gh repo edit <owner/repo> --enable-squash-merge=false`, named in that question)" — merge typed by hand; no stacked-PR handling.
- E7 Session report (prompt): stacked merge needed retarget child, merge parent with `--delete-branch`, `git rebase --onto origin/main <old-base-sha>`, lease push, merge child, all by hand.
- E8 `gh pr merge --help` (2.100.0) — "`-d, --delete-branch  Delete the local and remote branch after merge`"; `gh repo view --json` lists `squashMergeAllowed`, `rebaseMergeAllowed`; `gh pr view --json` lists `state`, `baseRefName`, `headRefName`, `headRefOid` — everything needed exists in gh >= 2.100.
- E9 `skills/execute/SKILL.md:33` — "a detached worktree looping over `git rev-list --reverse <base>..HEAD` (prefer the loop in a linked worktree: `rebase --exec` exports `GIT_DIR` there…)" — loop rebuilt by hand each time.
- E10 `skills/pr-ready/SKILL.md:19` — "check … that each commit passes lint + the check on its own" — second caller of the per-commit check.
- E11 `skills/plan/scripts/common.sh:5` — "`[ -n "${GIT_WORK_TREE:-}" ] || unset GIT_DIR`"; `skills/plan/scripts/scripts.test.sh:6` — "`unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE …`" — git-env hygiene to reuse.
- E12 `skills/pr-ready/scripts/fold.sh:13` — "`[ -z "$(git status --porcelain)" ] || { echo "fold.sh: working tree not clean…`"; `skills/pr-ready/scripts/open-pr.sh:30` — "`[ -z "$(git status --porcelain)" ] || die "working tree not clean"`" — untracked files block both.
- E13 `skills/pr-ready/scripts/fold.sh:33` — "`git add -A openspec`" — an untracked file under `openspec/` would ride into the fold commit; elsewhere it cannot.
- E14 `skills/pr-ready/scripts/open-pr.test.sh:171` — "`touch untracked`" — the dirty-tree test uses an untracked file; must become a tracked edit.
- E15 `skills/pr-ready/scripts/open-pr.sh:44` — "`write() { if [ -n "$dry" ]; then printf '%q ' "$@"; echo; else "$@" >/dev/null; fi; }`"; `:46-48` — label lookup and `gh label create "$label" --color "$color" --description "Conventional commit type: $kind"` — dry-run and label pattern to share.
- E16 `skills/plan/scripts/common.sh:1-15` — shared lib sourced by every script; `skills/plan/scripts/AGENTS.md:19` — "Every slug-taking script (…) validates its slug with `slug_ok`".
- E17 `skills/plan/scripts/scripts.test.sh:8` — "`FOLD="$S/../../pr-ready/scripts/fold.sh"`"; `:55-63` slug loop; `:157-165` rg-absent loop — suite already tests scripts from other folders.
- E18 `tests/guards.test.sh:22-41` — merge guard greps `gh pr merge`; outsider guard greps `--json [^`]*author` and `collaborators/` — break once the SKILL text calls scripts.
- E19 `agents/planner.md:29` — proposal template carries only `Status:` and `Issue:`; no blocked-by or parent field exists.
- E20 `skills/standard/SKILL.md:35` — "issue types are org-only" — `type:*` labels stay.
- E21 `AGENTS.md:6`, `lefthook.yml:9,18`, `.github/workflows/ci.yml:36-40` — four suites; new tests go into existing suites, so no runner changes.
- E22 `README.md:81` — "`gh issue create` with label `type:bug|feat|chore`"; `README.md:87-99` Scripts table — docs to update.
- E23 `openspec/specs/workflow-guards/spec.md:9` — "before it pushes, force-pushes, opens or edits a pull request, merges, or changes repository settings" — already covers retargets; no delta needed.

## Goals / Non-Goals
**Goals:**
- Every `gh`/`git` write sequence a skill types today becomes one script with `--dry-run` where it writes remotely (E1–E10).
- `fold.sh`/`open-pr.sh` stop refusing on unrelated untracked files (E12).

**Non-Goals:**
- Blocked-by / parent on created issues — no proposal field exists (E19); reopen when a plan needs a dependent issue (add `Blocked-by:` header → `gh issue create --blocked-by`, E8).
- Automating the child rebase + lease push after a stacked merge — rebase can conflict and needs judgment; reopen when it is run often without conflicts.
- Fork (cross-repository) PRs in `merge-pr.sh` — pr-ready only merges own branches; reopen when a fork PR is merged with it.
- `--match-head-commit` on merge — the real run re-reads the head, so it binds nothing to the dry run; reopen if dry-run output gets passed back in.
- GitHub MCP server — model-driven, not callable from scripts (user decision).

## Decisions
- **Helpers in `common.sh`**: move `write()` (reads `$dry`) and the label lookup/create as `ensure_label <kind>` out of `open-pr.sh` (E15); add `tracked_clean() { git diff --quiet && git diff --cached --quiet; }`. Each has two or more callers. `git diff --quiet HEAD` lost: misses an index change reverted in the worktree, which `git commit` in fold would still commit (E13).
- **fold.sh**: `tracked_clean` plus refuse untracked non-ignored files under `openspec/` (`git ls-files -o --exclude-standard -- openspec`), because `git add -A openspec` would sweep them in (E13). Untracked elsewhere is ignored. Simpler "tracked only" lost: silently commits stray spec files.
- **open-pr.sh**: `tracked_clean` only; untracked files never reach a push.
- **Location**: `read-issue.sh`, `create-issue.sh`, `verify-commits.sh` in `skills/plan/scripts/` — each has two skill callers (E1/E2, E3/E4, E9/E10) and that folder is where shared scripts live (E16); tests go into `scripts.test.sh`, which already tests scripts outside its folder (E17). `merge-pr.sh` in `skills/pr-ready/scripts/`, tested in `open-pr.test.sh` (bare origin + gh stub already there). No new suite (E21). `execute/scripts/` lost: a new folder for one script used by two skills.
- **read-issue.sh `<n|#n|url>`**: arg must match `^#?[1-9][0-9]*$` or `^https://<any host>/<owner>/<repo>/issues/<n>$` (n positive, no leading zero), else exit 2 before any gh call. One `gh issue view --json url,title,body,author,comments,labels,parent,blockedBy,subIssues --jq 'tojson, .url, .author.login, .comments[].author.login'`: print the first line (the issue JSON); then per distinct login from the same response, `collaborator <login>` when it matches `^[A-Za-z0-9-]+$` and `gh api repos/<owner>/<repo>/collaborators/<login> --silent` succeeds, else `outsider <login>`. JSON annotation in a `--jq` lost: needs jq to test offline, and a stub cannot evaluate it.
- **create-issue.sh `<slug> [--dry-run]`**: `slug_ok`, `issue_of`. `Status:` must be draft or approved (a done change is never re-approved). Issue already named → `set-status.sh <slug> approved <issue>` when draft (covers `/solo:plan #n`), nothing when already approved. Else title = first `- ` line under `## What Changes` (die if none), kind from slug prefix (`fix-`→bug, `add-`→feat, else chore, E5), body = the proposal's `## Why` and `## What Changes` sections verbatim (awk, up to the next `## `) plus a `Change: openspec/changes/<slug>/` line, passed with `--body-file` from a temp file so contributors without the change folder see the plan while the proposal stays the source; `ensure_label`, `gh issue create … --label type:<kind> --assignee @me`, parse `owner/repo#n` from the returned URL (any host), then `set-status.sh`. Dry run prints the writes and the set-status call. A `Type:` proposal header lost: new field for information the slug already carries (see Open Questions).
- **merge-pr.sh `<n> [--dry-run]`**: n must be `^[1-9][0-9]*$` (exit 2). Read `state,isDraft,mergeable,mergeStateStatus,baseRefName,headRefName,headRefOid` and `nameWithOwner,squashMergeAllowed,rebaseMergeAllowed`; refuse not-OPEN, draft, CONFLICTING, BLOCKED/DIRTY/BEHIND/UNKNOWN or rebase disallowed before any write. Writes via `write`, in order: `gh repo edit --enable-squash-merge=false` when squash allowed; `gh pr merge <n> --repo <owner/repo> --rebase` (`--repo` turns off gh's local branch handling: cli/cli `pkg/cmd/pr/merge/merge.go:124` at v2.100.0); `gh pr edit <c> --repo <owner/repo> --base <base>` for each open PR from `gh pr list --base <head> --state open`; per child, print `git rebase --onto origin/<base> <headRefOid> <child-branch>` then lease push as the next step (E7); `gh api -X DELETE repos/<owner/repo>/git/refs/heads/<head>`. Then fetch `+refs/heads/<base>:refs/remotes/origin/<base>` and `git merge --ff-only origin/<base>` when `<base>` is checked out; the delete, fetch or fast-forward failing after the merge is a warning, exit 0. Merging without `--delete-branch` and deleting after the retarget means no child is written unless the merge succeeded, and no child is closed by the delete; the rebase can conflict, so it is printed.
- **verify-commits.sh `<base> -- <check…>`**: source `common.sh`, then unset the git env list from E11 so the check never sees the caller's repo. `mktemp -d` + `git worktree add --detach`; trap runs `git worktree remove --force` on it (fallback `rm -rf`), never a repo-wide `git worktree prune`, which would drop the caller's moved worktrees. The check is one argv; callers wrap compound checks and dep installs in `bash -c`. Per sha from `git rev-list --reverse <base>..HEAD`: `checkout --force --detach`, `clean -fdq` (ignored files such as installed deps stay), run the check in the worktree; print `ok <sha> <subject>`; first failure → exit 1 naming the sha. `git rebase --exec` lost: exports `GIT_DIR` in linked worktrees (E9).
- **Skill text**: plan steps 0 and 5, investigate, ship step 4, pr-ready §3 and §6, execute §10 call the scripts; pr-ready §6 shows `merge-pr.sh <n> --dry-run` in the AskUserQuestion, same as §5. Guards follow the text (E18).

## Risks / Trade-offs
- The collaborator endpoint may need push access; a caller without it sees every author as outsider — fails safe.
- GitHub may itself retarget children when a merged head branch is deleted; unverified for API deletes, and the explicit retarget makes it moot.
- A fresh worktree has no ignored files (installed deps, local config); a check that needs them must install them itself.
- Slug-prefix typing labels `remove-*` and `update-*` as chore even when user-visible.

## Open Questions
- Issue type: keep the slug-prefix rule (`fix-`→bug, `add-`→feat, else chore), or add a `Type: feat|bug|chore` line to the proposal template that `create-issue.sh` reads? The latter changes the "Issue type label follows the slug" requirement and the planner template.
