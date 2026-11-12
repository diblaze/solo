#!/usr/bin/env bash
# Offline tests for issue.sh: stub gh on PATH, throwaway git repo.
# Usage: bash skills/issues/scripts/issue.test.sh
set -euo pipefail
# The throwaway repo below must not inherit a caller's repo (git rebase --exec exports GIT_DIR).
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR GIT_PREFIX
I="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/issue.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export GIT_CEILING_DIRECTORIES="$tmp" GH_LOG="$tmp/gh.log"

stub="$tmp/stub"
mkdir -p "$stub"
# gh: logs each call's argv (one line, tab-separated), answers from STUB_* env, keeps the last
# --body-file at $GH_LOG.body. Lists run the --jq expression they get through real jq on
# $STUB_JSON, so the printed format is tested and not stubbed.
cat >"$stub/gh" <<'EOF'
#!/usr/bin/env bash
(IFS=$'\t'; echo "$*") >>"$GH_LOG"
prev="" jqx=""
for a in "$@"; do
  [ "$prev" != --body-file ] || cp "$a" "$GH_LOG.body"
  [ "$prev" != --jq ] || jqx="$a"
  prev="$a"
done
case "$1 $2" in
  "issue create") echo "${STUB_ISSUE_URL-}" ;;
  "issue list" | "api --paginate") jq -r "$jqx" <<<"${STUB_JSON:-[]}" ;;
esac
EOF
chmod +x "$stub/gh"
export PATH="$stub:$PATH"

fail() { echo "FAIL: $case: $*" >&2; exit 1; }
# fails <rc> <cmd…>: run cmd, keep stdout/stderr in $tmp/out, $tmp/err, assert its exit code.
fails() {
  local want="$1" rc=0; shift
  "$@" >"$tmp/out" 2>"$tmp/err" || rc=$?
  [ "$rc" -eq "$want" ] || fail "exit $rc, want $want: $* (stderr: $(cat "$tmp/err"))"
}
# start <case>: name the case, empty the gh log.
start() { case="$1"; : >"$GH_LOG"; rm -f "$GH_LOG.body"; }
# logged <argv…>: the gh log holds exactly this call (one line).
logged() { (IFS=$'\t'; rg -qxF -- "$*" "$GH_LOG") || fail "gh log lacks: $* (log: $(cat "$GH_LOG"))"; }
# calls <n>: the gh log holds n calls.
calls() { [ "$(wc -l <"$GH_LOG")" -eq "$1" ] || fail "want $1 gh calls: $(cat "$GH_LOG")"; }
out() { [ "$(cat "$tmp/out")" = "$1" ] || fail "stdout: $(cat "$tmp/out"), want: $1"; }

cd "$(mktemp -d "$tmp/r.XXXX")"
repo="$PWD"
git init -q && git config user.email t@example.com && git config user.name t
echo body >b.md && echo comment >c.md
git add -A && git commit -q -m init

start "Issue created with type and milestone"
STUB_ISSUE_URL=https://github.com/o/r/issues/9 \
  fails 0 "$I" create --title Crash --body-file b.md --type bug --milestone v1 --blocked-by 3
logged issue create --title Crash --body-file "$repo/b.md" --type Bug --assignee @me --milestone v1 --blocked-by 3
cmp -s b.md "$GH_LOG.body" || fail "body file not passed"
out 'o/r#9'
calls 1

start "Issue assigned to another login"
STUB_ISSUE_URL=https://github.com/o/r/issues/9 fails 0 "$I" create --title Tidy --body-file b.md --type chore --assignee alice
logged issue create --title Tidy --body-file "$repo/b.md" --type Task --assignee alice

start "Body file found from a subdirectory"
mkdir -p sub && echo deep >sub/d.md
(cd sub && STUB_ISSUE_URL=https://github.com/o/r/issues/9 fails 0 "$I" create --title T --body-file d.md --type bug)
cmp -s sub/d.md "$GH_LOG.body" || fail "relative body file not resolved from the caller's directory"

start "Issue URL missing"
fails 1 "$I" create --title T --body-file b.md --type bug

start "Issue type changed"
fails 0 "$I" edit 4 --type feat
logged issue edit 4 --type Feature
calls 1
! rg -q 'label' "$GH_LOG" || fail "a label was touched"

start "Title, milestone and assignee edited"
fails 0 "$I" edit '#4' --title New --milestone v2 --add-assignee alice --remove-assignee bob --body-file b.md
logged issue edit 4 --title New --milestone v2 --add-assignee alice --remove-assignee bob --body-file "$repo/b.md"
calls 1

start "Milestone removed"
fails 0 "$I" edit 4 --remove-milestone
logged issue edit 4 --remove-milestone

start "Empty edit refused"
fails 2 "$I" edit 4
calls 0

start "Blocked-by added and removed"
fails 0 "$I" edit 4 --add-blocked-by 3 --remove-blocked-by 2
logged issue edit 4 --add-blocked-by 3 --remove-blocked-by 2

start "Comment posted from a file"
fails 0 "$I" comment 4 --body-file c.md
logged issue comment 4 --body-file "$repo/c.md"
cmp -s c.md "$GH_LOG.body" || fail "comment body not passed"
fails 2 "$I" comment 4

start "Issue closed as not planned"
fails 0 "$I" close 4 --reason not-planned
logged issue close 4 --reason 'not planned'
start "Issue closed as completed"
fails 0 "$I" close 4
logged issue close 4 --reason completed

start "Issue closed as duplicate"
fails 0 "$I" close 4 --duplicate-of 2
logged issue close 4 --duplicate-of 2

start "Issue reopened"
fails 0 "$I" reopen 4
logged issue reopen 4

start "Unknown close reason refused"
fails 2 "$I" close 4 --reason wontfix
calls 0

start "Bad issue input refused"
fails 2 "$I" edit '1; touch INJECTED' --title x
fails 2 "$I" create --title T --body-file b.md --type feature
fails 2 "$I" create --title T --body-file missing.md --type bug
fails 2 "$I" create --title T --body-file b.md --type bug --assignee 'a b'
fails 2 "$I" create --title T --body-file b.md --type bug --assignee -x
fails 2 "$I" edit 4 --add-assignee --
fails 2 "$I" edit 4 --title ''
fails 2 "$I" edit 4 --milestone v1 --remove-milestone
fails 2 "$I" edit 4 --dry-run --title x
fails 2 "$I" close 4 '--duplicate-of junk' 5
fails 2 "$I" close 4 '' ''
fails 2 "$I" close 4 --reason
fails 2 "$I" --dry-run
fails 2 "$I" create --title T --body-file b.md
fails 2 "$I" create --title T --body-file b.md --type bug --blocked-by x
fails 2 "$I" create --title
fails 2 "$I" edit 4 --colour red
fails 2 "$I" edit 0 --title x
fails 2 "$I" reopen 4 extra
fails 2 "$I" delete 4
fails 2 "$I"
calls 0
[ -z "$(find "$tmp" -name INJECTED)" ] || fail "INJECTED was created"

start "Issue write dry run"
fails 0 "$I" create --title T --body-file b.md --type feat --dry-run
rg -q '^gh issue create --title T .* --type Feature ' "$tmp/out" || fail "no issue create line: $(cat "$tmp/out")"
fails 0 "$I" edit 4 --type feat --dry-run
out 'gh issue edit 4 --type Feature '
fails 0 "$I" close 4 --dry-run
out 'gh issue close 4 --reason completed '
fails 0 "$I" comment 4 --body-file c.md --dry-run
fails 0 "$I" edit 4 --title --dry-run --dry-run
out 'gh issue edit 4 --title --dry-run '
fails 0 "$I" reopen 4 --dry-run
calls 0

echo "issue.test.sh: ok"
