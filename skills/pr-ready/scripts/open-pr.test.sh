#!/usr/bin/env bash
# Offline test for open-pr.sh: a local bare repo as origin and a stub `gh` on PATH.
set -euo pipefail
script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/open-pr.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir "$tmp/bin"
cat >"$tmp/bin/gh" <<'EOF'
#!/usr/bin/env bash
echo "$*" >>"$GH_LOG"
case "$1 $2" in
  "label list") [ -z "${STUB_LABELS:-}" ] || echo "$STUB_LABELS" ;;
  "pr list") [ -z "${STUB_PR:-}" ] || echo "$STUB_PR" ;;
  "pr view") if [[ "$*" == *"--json labels"* ]]; then [ -z "${STUB_PR_LABELS:-}" ] || echo "$STUB_PR_LABELS"
             else echo "https://example.test/pr/${STUB_PR:-1}"; fi ;;
esac
EOF
chmod +x "$tmp/bin/gh"
export PATH="$tmp/bin:$PATH" GH_LOG="$tmp/gh.log"

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
rg -qF 'Closes #12' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"
refute_log 'pr '; ! on_remote || fail "pushed"

case_ "Body carries Closes" "feat: a"
archived "Issue: o/r#12"
export STUB_LABELS=type:feat
echo "Closes #12" >"$body"
run main --title t --body-file "$body"
assert_log 'pr create'

case_ "Closes of another issue does not count" "feat: a"
archived "Issue: o/r#1"
export STUB_LABELS=type:feat
echo "Closes #12" >"$body"
fails 1 main --title t --body-file "$body"
rg -qF 'Closes #1' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"

case_ "Run from a subdirectory" "feat: a"
archived "Issue: o/r#12"
export STUB_LABELS=type:feat
(cd openspec && fails 1 main --title t --body-file "$body")
refute_log 'pr '

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
touch untracked
fails 1 main --title t --body-file "$body"
rg -q 'not clean' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"
[ ! -s "$GH_LOG" ] || fail "gh called"; ! on_remote || fail "pushed"
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

echo "open-pr.test.sh: ok"
