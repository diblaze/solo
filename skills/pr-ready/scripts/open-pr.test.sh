#!/usr/bin/env bash
# Offline test for open-pr.sh: a local bare repo as origin and a stub `gh` on PATH.
set -euo pipefail
# Throwaway repos below must not inherit a caller's repo (git rebase --exec exports GIT_DIR).
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR GIT_PREFIX
script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/open-pr.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir "$tmp/bin"
cat >"$tmp/bin/gh" <<'EOF'
#!/usr/bin/env bash
echo "$*" >>"$GH_LOG"
case "$1 $2" in
  "label list") [ -z "${STUB_LABELS:-}" ] || echo "$STUB_LABELS" ;;
  "pr list") if [[ "$*" == *--base* ]]; then [ -z "${STUB_CHILDREN:-}" ] || echo "$STUB_CHILDREN"
             else [ -z "${STUB_PR:-}" ] || echo "$STUB_PR"; fi ;;
  "pr view") if [[ "$*" == *"--json labels"* ]]; then [ -z "${STUB_PR_LABELS:-}" ] || echo "$STUB_PR_LABELS"
             elif [[ "$*" == *"--json state"* ]]; then echo "$STUB_PR_VIEW"
             else echo "https://example.test/pr/${STUB_PR:-1}"; fi ;;
  "repo view") echo "$STUB_REPO" ;;
  # The merge moves origin's base to STUB_MERGE_SHA (when set); STUB_MERGE_FAIL makes it fail.
  "pr merge") [ -z "${STUB_MERGE_FAIL:-}" ] || exit 1
              [ -z "${STUB_MERGE_SHA:-}" ] || git --git-dir="$STUB_REMOTE" update-ref refs/heads/main "$STUB_MERGE_SHA" ;;
  # The branch delete removes the head ref; STUB_DELETE_FAIL makes it fail.
  "api -X") [ -z "${STUB_DELETE_FAIL:-}" ] || exit 1
            git --git-dir="$STUB_REMOTE" update-ref -d "refs/heads/$STUB_HEAD" 2>/dev/null || true ;;
esac
EOF
chmod +x "$tmp/bin/gh"
export PATH="$tmp/bin:$PATH" GH_LOG="$tmp/gh.log" STUB_REMOTE="$tmp/remote"

git init -q --bare "$tmp/remote"
git init -q -b main "$tmp/repo"
cd "$tmp/repo"
git config user.email t@example.test
git config user.name t
git config commit.gpgsign false
git remote add origin "$tmp/remote"
git commit -q --allow-empty -m "chore: init"
git push -q origin main

body="$tmp/body.md"
n=0
fail() { echo "FAIL [$name]: $*" >&2; exit 1; }
case_() { # case_ <name> <subject>...: fresh branch off main with one empty commit per subject
  name="$1"; shift
  n=$((n + 1)); branch="b$n"
  git checkout -q main
  git checkout -q -b "$branch"
  for s in "$@"; do git commit -q --allow-empty -m "$s"; done
  : >"$GH_LOG"
  unset STUB_LABELS STUB_PR STUB_PR_LABELS
  echo "body" >"$body"
}
assert_log() { rg -q -- "$1" "$GH_LOG" || fail "log lacks /$1/: $(cat "$GH_LOG")"; }
refute_log() { ! rg -q -- "$1" "$GH_LOG" || fail "log has /$1/: $(cat "$GH_LOG")"; }
on_remote() { git ls-remote --exit-code origin "refs/heads/$branch" >/dev/null 2>&1; }
run() { out="$("$script" "$@" 2>"$tmp/err")"; }
fails() { local want="$1"; shift; set +e; "$script" "$@" >/dev/null 2>"$tmp/err"; rc=$?; set -e
  [ "$rc" -eq "$want" ] || fail "exit $rc, want $want: $(cat "$tmp/err")"; }
labels() { rg -o -- '--label \S+' "$GH_LOG" | wc -l; }

# Label from commit subjects
case_ "Feature commit present" "docs(spec): fold x" "fix(a): b" "feat(a)!: c"
export STUB_LABELS=type:feat
run main --title t --body-file "$body"
assert_log 'pr create .*--label type:feat'; [ "$(labels)" -eq 1 ] || fail "labels: $(labels)"

case_ "Fix without feature" "fix(a): b" "docs: c"
export STUB_LABELS=type:bug
run main --title t --body-file "$body"
assert_log 'pr create .*--label type:bug'; [ "$(labels)" -eq 1 ] || fail "labels: $(labels)"

case_ "Neither feature nor fix" "docs(spec): fold x" "chore: y"
export STUB_LABELS=type:chore
run main --title t --body-file "$body"
assert_log 'pr create .*--label type:chore'; [ "$(labels)" -eq 1 ] || fail "labels: $(labels)"

# New PR, label handling, existing PR
case_ "New PR assigned" "feat: a"
export STUB_LABELS=type:feat
run main --title "feat: a" --body-file "$body"
[ "$(git rev-parse "origin/$branch")" = "$(git rev-parse HEAD)" ] || fail "branch not pushed"
[ "$(git rev-parse --abbrev-ref '@{u}')" = "origin/$branch" ] || fail "no upstream"
assert_log "pr create --base main --title feat: a --body-file $body --label type:feat --assignee @me"
[ "$out" = "https://example.test/pr/1" ] || fail "url: $out"

case_ "Label absent in repository" "feat: a"
run main --title t --body-file "$body"
assert_log 'label create type:feat --color 0052CC'
[ "$(rg -n 'label create' "$GH_LOG" | cut -d: -f1)" -lt "$(rg -n 'pr create' "$GH_LOG" | cut -d: -f1)" ] || fail "label not created before PR"

case_ "Label already present" "chore: a"
export STUB_LABELS=type:chore
run main --title t --body-file "$body"
refute_log 'label create'

case_ "Existing open PR" "fix: a"
git push -q -u origin HEAD
git commit -q --amend --allow-empty -m "fix: b" # rewritten history: only a lease push updates the remote
export STUB_LABELS=type:bug STUB_PR=7 STUB_PR_LABELS=type:feat
run main --title "fix: a" --body-file "$body"
assert_log "pr edit 7 --base main --title fix: a --body-file $body --add-label type:bug --remove-label type:feat --add-assignee @me"
refute_log 'pr create'
[ "$(git rev-parse "origin/$branch")" = "$(git rev-parse HEAD)" ] || fail "remote not updated"
[ "$out" = "https://example.test/pr/7" ] || fail "url: $out"

case_ "Lease push refuses a foreign remote update" "fix: a"
git push -q -u origin HEAD
git clone -q "$tmp/remote" "$tmp/other" && git -C "$tmp/other" checkout -q "$branch"
git -C "$tmp/other" -c user.email=o@example.test -c user.name=o commit -q --allow-empty -m "fix: foreign"
git -C "$tmp/other" push -q origin "$branch"; rm -rf "$tmp/other"
git commit -q --amend --allow-empty -m "fix: b"
export STUB_LABELS=type:bug STUB_PR=7
set +e; "$script" main --title t --body-file "$body" >/dev/null 2>"$tmp/err"; rc=$?; set -e
[ "$rc" -ne 0 ] || fail "plain force push overwrote a foreign commit"
[ "$(git ls-remote origin "refs/heads/$branch" | cut -f1)" != "$(git rev-parse HEAD)" ] || fail "remote overwritten"

# Closes check
archived() { # archived <issue-line>: commit an archived proposal on the branch
  mkdir -p openspec/changes/archive/2026-01-01-x
  printf '# x\nStatus: done\n%s\n' "$1" >openspec/changes/archive/2026-01-01-x/proposal.md
  git add openspec && git commit -q -m "docs(spec): fold x"
}
case_ "Body missing Closes" "feat: a"
archived "Issue: o/r#12"
export STUB_LABELS=type:feat
fails 1 main --title t --body-file "$body"
rg -qF 'Closes o/r#12' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"
refute_log 'pr '; ! on_remote || fail "pushed"

case_ "Body carries Closes" "feat: a"
archived "Issue: o/r#12"
export STUB_LABELS=type:feat
echo "Closes o/r#12" >"$body"
run main --title t --body-file "$body"
assert_log 'pr create'

case_ "Closes of another issue does not count" "feat: a"
archived "Issue: o/r#1"
export STUB_LABELS=type:feat
echo "Closes o/r#12" >"$body"
fails 1 main --title t --body-file "$body"
rg -qF 'Closes o/r#1' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"

case_ "Run from a subdirectory" "feat: a"
archived "Issue: o/r#12"
export STUB_LABELS=type:feat
(cd openspec && fails 1 main --title t --body-file "$body")
rg -qF 'Closes o/r#12' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"
refute_log 'pr '

case_ "Malformed Issue line refused" "feat: a"
archived "Issue: #12"
unset STUB_LABELS
echo "Closes #12" >"$body"
fails 1 main --title t --body-file "$body"
rg -qF 'Issue' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"
refute_log 'pr '; refute_log 'label create'; ! on_remote || fail "pushed"

case_ "Archived change without issue" "feat: a"
archived "Issue: none"
export STUB_LABELS=type:feat
run main --title t --body-file "$body"
assert_log 'pr create'

# Preconditions
case_ "On the base branch"
git checkout -q main
fails 1 main --title t --body-file "$body"
rg -q 'main' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"
[ ! -s "$GH_LOG" ] || fail "gh called"

case_ "No commits ahead"
fails 1 main --title t --body-file "$body"
[ ! -s "$GH_LOG" ] || fail "gh called"; ! on_remote || fail "pushed"

case_ "Dirty working tree" "feat: a"
echo a >tracked && git add tracked && git commit -q -m "feat: tracked"
echo b >>tracked # unstaged
fails 1 main --title t --body-file "$body"
rg -q 'not clean' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"
[ ! -s "$GH_LOG" ] || fail "gh called"; ! on_remote || fail "pushed"
git add tracked # staged
fails 1 main --title t --body-file "$body"
rg -q 'not clean' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"
[ ! -s "$GH_LOG" ] || fail "gh called"; ! on_remote || fail "pushed"
git reset -q --hard

case_ "Untracked file allowed" "feat: a"
touch untracked
export STUB_LABELS=type:feat
run main --title t --body-file "$body"
assert_log 'pr create'
! git ls-tree -r --name-only "origin/$branch" | rg -qx untracked || fail "untracked file pushed"
rm untracked

case_ "Missing title or body" "feat: a"
fails 2 main --body-file "$body"
rg -q 'usage:' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"
fails 2 main --title t
rg -q 'usage:' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"
[ ! -s "$GH_LOG" ] || fail "gh called"; ! on_remote || fail "pushed"

# Dry run
case_ "Dry run on a new branch" "feat: a"
run main --title t --body-file "$body" --dry-run
[[ "$out" == *"pr create"*"--label type:feat --assignee @me"* ]] || fail "stdout: $out"
refute_log 'pr create'; refute_log 'label create'; ! on_remote || fail "pushed"

# merge-pr.sh
merge="$(dirname "$script")/merge-pr.sh"
line() { rg -n -m1 -- "$1" "$GH_LOG" | cut -d: -f1; }
view() { # view <state> <isDraft> <mergeable> <mergeStateStatus>: canned pr view for PR 5 from feat/x into main at abc123
  printf '%s\n' "$1" "$2" "$3" "$4" main feat/x abc123
}
mcase() { # mcase <name>: on main, an open mergeable PR 5; repo o/r allows rebase, not squash
  name="$1"; git checkout -q main; : >"$GH_LOG"
  STUB_PR_VIEW="$(view OPEN false MERGEABLE CLEAN)"
  export STUB_PR_VIEW STUB_REPO=$'o/r\nfalse\ntrue' STUB_CHILDREN="" STUB_HEAD=feat/x STUB_MERGE_SHA="" STUB_MERGE_FAIL="" STUB_DELETE_FAIL=""
}
mrun() { set +e; out="$("$merge" "$@" 2>"$tmp/err")"; rc=$?; set -e; }
nowrite() { refute_log 'repo edit'; refute_log 'pr edit'; refute_log 'pr merge'; refute_log 'api -X'; }

mcase "Rebase merge deletes the branch"
mrun 5
[ "$rc" -eq 0 ] || fail "exit $rc: $(cat "$tmp/err")"
[ "$(rg -c '^pr merge' "$GH_LOG")" -eq 1 ] || fail "merge calls: $(cat "$GH_LOG")"
assert_log '^pr merge 5 --repo o/r --rebase$'
assert_log '^api -X DELETE repos/o/r/git/refs/heads/feat/x$'
[ "$(line 'pr merge')" -lt "$(line 'api -X DELETE')" ] || fail "branch deleted before the merge: $(cat "$GH_LOG")"
refute_log 'repo edit'

mcase "Branch delete failure warns"
export STUB_DELETE_FAIL=1
mrun 5
[ "$rc" -eq 0 ] || fail "exit $rc after a remote merge: $(cat "$tmp/err")"
rg -q 'warning.*feat/x' "$tmp/err" || fail "no warning: $(cat "$tmp/err")"
[ "$(rg -c '^pr merge' "$GH_LOG")" -eq 1 ] || fail "merge calls: $(cat "$GH_LOG")"

mcase "Squash merging switched off first"
export STUB_REPO=$'o/r\ntrue\ntrue'
mrun 5
[ "$rc" -eq 0 ] || fail "exit $rc: $(cat "$tmp/err")"
assert_log '^repo edit --enable-squash-merge=false$'
[ "$(line 'repo edit')" -lt "$(line 'pr merge')" ] || fail "squash not switched off first: $(cat "$GH_LOG")"

mcase "Child PR retargeted"
export STUB_CHILDREN="6 feat/y"
mrun 5
[ "$rc" -eq 0 ] || fail "exit $rc: $(cat "$tmp/err")"
assert_log '^pr edit 6 --repo o/r --base main$'
[ "$(line 'pr merge')" -lt "$(line 'pr edit 6')" ] || fail "child retargeted before the merge: $(cat "$GH_LOG")"
[ "$(line 'pr edit 6')" -lt "$(line 'api -X DELETE')" ] || fail "branch deleted before the retarget: $(cat "$GH_LOG")"
[[ "$out" == *"#6"*"git rebase --onto origin/main abc123 feat/y"* ]] || fail "stdout: $out"

mcase "Failed merge leaves children untouched"
export STUB_CHILDREN="6 feat/y" STUB_MERGE_FAIL=1
mrun 5
[ "$rc" -ne 0 ] || fail "exit 0"
refute_log 'pr edit'; refute_log 'api -X'
[[ "$out" != *"PR #6 next"* ]] || fail "child steps printed: $out"

mcase "Bad PR number refused"
for bad in '5; touch INJECTED' 0 007; do
  mrun "$bad"
  [ "$rc" -eq 2 ] || fail "$bad: exit $rc"
  [ ! -s "$GH_LOG" ] || fail "$bad: gh called: $(cat "$GH_LOG")"
done
[ -z "$(find "$tmp" -name INJECTED)" ] || fail "INJECTED was created"

mcase "PR not open refused"
STUB_PR_VIEW="$(view CLOSED false MERGEABLE CLEAN)"
mrun 5
[ "$rc" -ne 0 ] || fail "exit 0"
rg -q CLOSED "$tmp/err" || fail "stderr: $(cat "$tmp/err")"
nowrite

mcase "Unmergeable PR refused"
export STUB_REPO=$'o/r\ntrue\ntrue' STUB_CHILDREN="6 feat/y"
for v in "true MERGEABLE CLEAN:draft" "false CONFLICTING DIRTY:CONFLICTING" "false MERGEABLE BLOCKED:BLOCKED" "false MERGEABLE DIRTY:DIRTY" "false MERGEABLE BEHIND:BEHIND" "false UNKNOWN UNKNOWN:UNKNOWN"; do
  read -r d m st <<<"${v%%:*}"
  STUB_PR_VIEW="$(view OPEN "$d" "$m" "$st")"; : >"$GH_LOG"
  mrun 5
  [ "$rc" -ne 0 ] || fail "$v: exit 0"
  rg -q "${v##*:}" "$tmp/err" || fail "$v: stderr: $(cat "$tmp/err")"
  nowrite
done

mcase "Rebase merging disabled refused"
export STUB_REPO=$'o/r\nfalse\nfalse'
mrun 5
[ "$rc" -ne 0 ] || fail "exit 0"
rg -q 'rebase merging' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"
nowrite

mcase "Merge dry run"
export STUB_REPO=$'o/r\ntrue\ntrue' STUB_CHILDREN="6 feat/y"
before="$(git rev-parse main)"
mrun 5 --dry-run
[ "$rc" -eq 0 ] || fail "exit $rc: $(cat "$tmp/err")"
for w in 'gh repo edit --enable-squash-merge=false' 'gh pr edit 6 --repo o/r --base main' 'gh pr merge 5 --repo o/r --rebase' 'gh api -X DELETE repos/o/r/git/refs/heads/feat/x'; do
  [[ "$out" == *"$w"* ]] || fail "stdout lacks $w: $out"
done
[[ "$out" == *"gh pr merge 5"*"gh pr edit 6"*"PR #6 next"*"gh api -X DELETE"* ]] || fail "dry run out of order: $out"
[[ "$out" != *--delete-branch* ]] || fail "merge still deletes the branch: $out"
nowrite
[ "$(git rev-parse main)" = "$before" ] || fail "local main moved"

mcase "Local base fast-forwarded"
git checkout -q -b merged && git commit -q --allow-empty -m "feat: merged" && sha="$(git rev-parse HEAD)"
git push -q origin "$sha:refs/heads/merged-tmp" && git checkout -q main && git branch -q -D merged
# No fetch refspec configured: only an explicit refspec updates origin/main.
fetchcfg="$(git config --get-all remote.origin.fetch)"; git config --unset-all remote.origin.fetch
export STUB_MERGE_SHA="$sha"
mrun 5
git config remote.origin.fetch "$fetchcfg"
[ "$rc" -eq 0 ] || fail "exit $rc: $(cat "$tmp/err")"
[ "$(git rev-parse main)" = "$sha" ] || fail "local main not fast-forwarded"

mcase "Local update failure after merge warns"
git checkout -q -b remote-side && git commit -q --allow-empty -m "feat: remote side" && rsha="$(git rev-parse HEAD)"
git push -q origin "$rsha:refs/heads/remote-tmp" && git checkout -q main && git branch -q -D remote-side
export STUB_MERGE_SHA="$rsha" # the merge moves origin/main to a commit local main lacks
git commit -q --allow-empty -m "chore: local only"
local_sha="$(git rev-parse HEAD)"
mrun 5
[ "$rc" -eq 0 ] || fail "exit $rc after a remote merge: $(cat "$tmp/err")"
rg -q 'warning.*main' "$tmp/err" || fail "no warning: $(cat "$tmp/err")"
[ "$(rg -c '^pr merge' "$GH_LOG")" -eq 1 ] || fail "merge calls: $(cat "$GH_LOG")"
[ "$(git rev-parse main)" = "$local_sha" ] || fail "local main changed"
git reset -q --hard "origin/main"

echo "open-pr.test.sh: ok"
