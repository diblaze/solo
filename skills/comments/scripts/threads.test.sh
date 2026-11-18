#!/usr/bin/env bash
# Offline tests for threads.sh: stub gh on PATH, throwaway git repo.
# Usage: bash skills/comments/scripts/threads.test.sh
set -euo pipefail
# The throwaway repo below must not inherit a caller's repo (git rebase --exec exports GIT_DIR).
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR GIT_PREFIX
T="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/threads.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export GIT_CEILING_DIRECTORIES="$tmp" GH_LOG="$tmp/gh.log"

stub="$tmp/stub"
mkdir -p "$stub"
# gh: logs each call's argv (one line, tab-separated, newlines in a query as spaces). `pr view` answers $STUB_PR_URL, or fails
# like gh when it is unset; a call with --jq runs that expression through real jq on $STUB_JSON,
# so the printed format is tested and not stubbed.
cat >"$stub/gh" <<'EOF'
#!/usr/bin/env bash
(IFS=$'\t'; printf '%s\n' "${*//$'\n'/ }") >>"$GH_LOG"
prev="" jqx=""
for a in "$@"; do
  [ "$prev" != --jq ] || jqx="$a"
  prev="$a"
done
if [ "$1 $2" = "pr view" ]; then
  [ -n "${STUB_PR_URL:-}" ] || { echo 'no pull requests found for branch "x"' >&2; exit 1; }
  echo "$STUB_PR_URL"
elif [ -n "$jqx" ]; then
  printf '%s' "${STUB_JSON-}" | jq -r "$jqx"
fi
EOF
chmod +x "$stub/gh"
export PATH="$stub:$PATH"

fail() { echo "FAIL: $case: $*" >&2; exit 1; }
# fails <rc|nonzero> <cmd…>: run cmd, keep stdout/stderr in $tmp/out, $tmp/err, assert its exit code.
fails() {
  local want="$1" rc=0; shift
  "$@" >"$tmp/out" 2>"$tmp/err" || rc=$?
  if [ "$want" = nonzero ]; then [ "$rc" -ne 0 ] || fail "exit 0, want non-zero: $*"
  else [ "$rc" -eq "$want" ] || fail "exit $rc, want $want: $* (stderr: $(cat "$tmp/err"))"; fi
}
# start <case>: name the case, empty the gh log.
start() { case="$1"; : >"$GH_LOG"; }
# logged <argv…>: the gh log holds exactly this call (one line).
logged() { (IFS=$'\t'; rg -qxF -- "$*" "$GH_LOG") || fail "gh log lacks: $* (log: $(cat "$GH_LOG"))"; }
calls() { [ "$(wc -l <"$GH_LOG")" -eq "$1" ] || fail "want $1 gh calls: $(cat "$GH_LOG")"; }
out() { [ "$(cat "$tmp/out")" = "$1" ] || fail "stdout: $(cat "$tmp/out"), want: $1"; }

cd "$(mktemp -d "$tmp/r.XXXX")"
git init -q && git config user.email t@example.com && git config user.name t
git commit -q --allow-empty -m init
repo="$PWD"
echo 'Fixed in abc123.' >b.md
export STUB_PR_URL=https://github.com/o/r/pull/7
export STUB_JSON='{"data":{"repository":{"pullRequest":{"reviewThreads":{"pageInfo":{"hasNextPage":false},"nodes":[
 {"id":"PRRT_a","isResolved":false,"isOutdated":false,"path":"src/x.sh","line":4,
  "comments":{"pageInfo":{"hasNextPage":false},"nodes":[{"databaseId":123,"author":{"login":"bot"},"body":"Quote this."},{"databaseId":124,"author":null,"body":"Agreed."}]}},
 {"id":"PRRT_b","isResolved":true,"isOutdated":true,"path":"README.md","line":null,
  "comments":{"pageInfo":{"hasNextPage":false},"nodes":[{"databaseId":200,"author":{"login":"alice"},"body":"Typo."}]}}]}}}}}'
open=$'THREAD PRRT_a resolved=false outdated=false\npath: src/x.sh line: 4 replyToId: 123\nbot: Quote this.\nghost: Agreed.\n----'

start "Unresolved threads listed"
fails 0 "$T" list
out "$(printf '# total: 2 | unresolved: 1\n%s' "$open")"
rg -q $'^api\tgraphql\t-f\towner=o\t-f\trepo=r\t-F\tpr=7\t' "$GH_LOG" || fail "graphql argv: $(cat "$GH_LOG")"
logged pr view --json url --jq .url
fails 0 "$T" list '#7'
logged pr view 7 --json url --jq .url

start "All threads listed"
fails 0 "$T" list --all
out "$(printf '# total: 2 | unresolved: 1\n%s\nTHREAD PRRT_b resolved=true outdated=true\npath: README.md line: - replyToId: 200\nalice: Typo.\n----' "$open")"

start "Reply posted from a file"
fails 0 "$T" reply 123 --body-file b.md --pr 7
logged pr view 7 --json url --jq .url
logged api repos/o/r/pulls/7/comments/123/replies -F "body=@$repo/b.md" --silent
calls 2

start "Threads resolved"
fails 0 "$T" resolve PRRT_a PRRT_b
out $'PRRT_a resolved\nPRRT_b resolved'
calls 2
rg -q $'^api\tgraphql\t-f\tthreadId=PRRT_a\t' "$GH_LOG" && rg -q $'^api\tgraphql\t-f\tthreadId=PRRT_b\t' "$GH_LOG" || fail "log: $(cat "$GH_LOG")"

start "Bad thread input refused"
for bad in "reply abc --body-file b.md" "reply 123" "reply 123 --body-file missing.md" "reply 123 --body-file" \
  "reply 123 --body-file b.md --pr 0" "reply 123 --body-file b.md --color red" "resolve 123" "resolve" \
  "list 0" "list 7 8" "list --mine" "bogus" ""; do
  # shellcheck disable=SC2086
  fails 2 "$T" $bad
done
fails 2 "$T" resolve 'PRRT_x; touch INJECTED'
calls 0
[ ! -e INJECTED ] || fail "INJECTED exists"

start "Branch without a pull request refused"
STUB_PR_URL='' fails nonzero "$T" list
STUB_PR_URL='' fails nonzero "$T" reply 123 --body-file b.md
calls 2
! rg -q $'^api\t' "$GH_LOG" || fail "wrote without a pull request: $(cat "$GH_LOG")"

start "Thread write dry run"
fails 0 "$T" reply 123 --body-file b.md --dry-run
rg -qF "gh api repos/o/r/pulls/7/comments/123/replies -F body=@$repo/b.md --silent" "$tmp/out" || fail "stdout: $(cat "$tmp/out")"
rg -qxF 'Fixed in abc123.' "$tmp/out" || fail "dry run does not show the reply text: $(cat "$tmp/out")"
fails 0 "$T" resolve PRRT_a --dry-run
rg -q '^gh api graphql -f threadId=PRRT_a ' "$tmp/out" || fail "stdout: $(cat "$tmp/out")"
calls 1
logged pr view --json url --jq .url

echo "threads.test.sh: ok"
