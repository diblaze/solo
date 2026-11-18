#!/usr/bin/env bash
# Offline tests for review-md.sh: throwaway repos whose base is refs/remotes/origin/main.
# Usage: bash skills/review/scripts/review-md.test.sh
set -euo pipefail
# Throwaway repos below must not inherit a caller's repo (git rebase --exec exports GIT_DIR).
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR GIT_PREFIX
RULES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/review-md.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export GIT_CEILING_DIRECTORIES="$tmp"

fail() { echo "FAIL: $case: $*" >&2; exit 1; }
# run <rc> <args…>: run review-md.sh, keep stdout/stderr in $tmp/out, $tmp/err, assert its exit code.
run() {
  local want="$1" rc=0; shift
  "$RULES" "$@" >"$tmp/out" 2>"$tmp/err" || rc=$?
  [ "$rc" -eq "$want" ] || fail "exit $rc, want $want: $* (stderr: $(cat "$tmp/err"))"
}
# newrepo <case> <path=text…>: a repo whose first commit, also origin/main, holds the given files.
newrepo() {
  case="$1"; shift
  cd "$(mktemp -d "$tmp/r.XXXX")"
  git init -q -b main && git config user.email t@example.com && git config user.name t
  local f
  for f in "$@"; do mkdir -p "$(dirname "${f%%=*}")" && printf '%s\n' "${f#*=}" >"${f%%=*}"; done
  touch keep && git add -A && git commit -q -m base && git update-ref refs/remotes/origin/main HEAD
}

newrepo "Rules read from the base ref" "REVIEW.md=flag sleeps"
echo 'flag nothing' >REVIEW.md && mkdir src && echo 'skip all' >src/REVIEW.md && touch src/a.sh
git add -A && git commit -q -m loosen && echo 'flag nothing either' >REVIEW.md
run 0
[ "$(cat "$tmp/out")" = $'== REVIEW.md ==\nflag sleeps' ] || fail "stdout: $(cat "$tmp/out")"

newrepo "Nearest rules file per path" "REVIEW.md=root rules" "src/REVIEW.md=src rules" "src/api/x.sh=x" "docs/z.md=z"
echo y >src/api/x.sh && echo y >src/y.sh && echo y >docs/z.md && git add -A && git commit -q -m change
run 0
[ "$(cat "$tmp/out")" = $'== REVIEW.md ==\nroot rules\n== src/REVIEW.md ==\nsrc rules' ] || fail "stdout: $(cat "$tmp/out")"

newrepo "No rules file prints nothing" "src/a.sh=a"
echo b >src/a.sh
run 0
[ ! -s "$tmp/out" ] || fail "stdout: $(cat "$tmp/out")"

newrepo "Changed files found on the branch" "src/REVIEW.md=src rules" "lib/REVIEW.md=lib rules" "src/a.sh=a" "docs/REVIEW.md=docs rules"
echo changed >src/a.sh && git commit -q -am change && touch lib/b.sh
(cd src && run 0)
rg -qxF '== src/REVIEW.md ==' "$tmp/out" && rg -qxF '== lib/REVIEW.md ==' "$tmp/out" || fail "stdout: $(cat "$tmp/out")"
! rg -qF 'docs/REVIEW.md' "$tmp/out" || fail "printed rules for an unchanged directory: $(cat "$tmp/out")"

newrepo "Unknown base ref refused" "REVIEW.md=root rules"
run 1 --base origin/nope
rg -qF 'origin/nope' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"
[ ! -s "$tmp/out" ] || fail "stdout: $(cat "$tmp/out")"
run 2 src/a.sh

newrepo "Unrelated history refused" "REVIEW.md=root rules"
git switch -q --orphan other && touch o && git add o && git commit -q -m other
run 1
rg -qF 'share no history' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"
[ ! -s "$tmp/out" ] || fail "stdout: $(cat "$tmp/out")"

echo "review-md.test.sh: ok"
