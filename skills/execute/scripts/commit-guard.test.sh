#!/usr/bin/env bash
# Offline tests for commit-guard.sh: stub PreToolUse JSON on stdin, throwaway git repos.
# Usage: bash skills/execute/scripts/commit-guard.test.sh
set -euo pipefail
# The throwaway repos below must not inherit a caller's repo (git rebase --exec exports GIT_DIR).
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR GIT_PREFIX
G="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commit-guard.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export GIT_CEILING_DIRECTORIES="$tmp"

fail() { echo "FAIL: $case: $*" >&2; exit 1; }
# guard <want-exit> <cwd> <command>: feed the guard a Bash PreToolUse event, assert its exit code.
guard() {
  local want="$1" rc=0
  jq -n --arg cwd "$2" --arg cmd "$3" '{hook_event_name: "PreToolUse", cwd: $cwd, tool_name: "Bash", tool_input: {command: $cmd}}' \
    | bash "$G" >"$tmp/out" 2>"$tmp/err" || rc=$?
  [ "$rc" -eq "$want" ] || fail "exit $rc, want $want for '$3' in $2 (stderr: $(cat "$tmp/err"))"
}
# repo <branch>: a fresh repo on that branch with one commit; prints its path.
repo() {
  local r; r="$(mktemp -d "$tmp/r.XXXX")"
  git -C "$r" init -q -b "$1" && git -C "$r" config user.email t@example.com && git -C "$r" config user.name t
  echo x >"$r/a.txt" && git -C "$r" add a.txt && git -C "$r" commit -q -m init
  echo "$r"
}
# change <repo> <slug> <status> [archive]: write a change proposal with that status (under archive/ if asked).
change() {
  local d="$1/openspec/changes${4:+/archive}/$2"
  mkdir -p "$d" && printf '# Proposal\n\nStatus: %s\nIssue: none\n' "$3" >"$d/proposal.md"
}

case="Change commit on main refused"
for b in main master; do
  r="$(repo "$b")"; change "$r" x approved; echo y >"$r/a.txt"
  git -C "$r" add openspec a.txt
  guard 2 "$r" "git commit -m m"
  rg -q '\bx\b' "$tmp/err" && rg -qF 'git switch -c' "$tmp/err" || fail "stderr names neither the slug nor git switch -c: $(cat "$tmp/err")"
  guard 2 "$r/openspec" "git commit -m m"
  guard 2 "$tmp" "git -C $r commit -m m"
  guard 2 "$tmp" "cd $r && git commit -m m"
  guard 2 "$tmp" "cd \"$r\" && git commit -m m"
  guard 2 "$tmp" "(cd $r && git commit -m m)"
  guard 2 "$tmp" "cd /nowhere; cd $r && git commit -m m"
  guard 2 "$tmp" "git -C '$r' commit -m m"
  guard 2 "$r" "env GIT_EDITOR=true git commit -m m"
  guard 2 "$r" "git -c core.hooksPath=/dev/null commit -q -m m"
  git -C "$r" reset -q
  guard 2 "$r" "git add openspec/changes/x/ a.txt && git commit -m m"
  guard 2 "$r" "git add -- a.txt \"openspec/changes/x\" && git commit -m m"
  guard 2 "$r" $'git add openspec/changes/x a.txt\ngit commit -m m'
  guard 2 "$r" "git add -A && git commit -m m"
  guard 2 "$r" "git add . && git commit -m m"
  guard 2 "${r%/*}" "cd ${r##*/} && git add openspec a.txt && git commit -m m"
  HOME="${r%/*}" guard 2 "$tmp" "git -C ~/${r##*/} add openspec a.txt && git -C ~/${r##*/} commit -m m"
done
# commit -a takes modified tracked files: a tracked approved folder with edits plus code.
r="$(repo main)"; change "$r" x approved; git -C "$r" add openspec && git -C "$r" commit -q -m plan
echo more >>"$r/openspec/changes/x/proposal.md"; echo y >"$r/a.txt"
guard 2 "$r" "git commit -am m"

case="Commit on a branch allowed"
r="$(repo main)"; change "$r" x approved; echo y >"$r/a.txt"; git -C "$r" switch -q -c feat/x; git -C "$r" add openspec a.txt
guard 0 "$r" "git commit -m m"
guard 0 "$tmp" "cd $r && git commit -m m"
m="$(repo main)"
guard 0 "$m" "git -C $r commit -m m"
guard 0 "$r" "git -C $m status && git commit -m m"

case="Unrelated commit on main allowed"
# A repo that commits straight to main, with approved changes tracked and untracked in its tree.
r="$(repo main)"; change "$r" y approved; git -C "$r" add openspec && git -C "$r" commit -q -m y
change "$r" x approved; echo y >"$r/a.txt"; git -C "$r" add a.txt
guard 0 "$r" "git commit -m m"
guard 0 "$r" "git commit -am 'docs: see openspec/changes/x for the plan'"
change "$r" x-v2 draft; guard 0 "$r" "git add openspec/changes/x-v2 && git commit -m m"
git -C "$r" reset -q; change "$r" old approved archive; git -C "$r" add openspec/changes/archive a.txt
guard 0 "$r" "git commit -m m"
# Planning commits: only openspec/ files, even of an approved change, pass.
git -C "$r" reset -q; git -C "$r" checkout -q -- a.txt
guard 0 "$r" "git add openspec/changes/x && git commit -m 'docs: plan x'"
echo tick >>"$r/openspec/changes/y/proposal.md"
guard 0 "$r" "git add openspec/changes/y/proposal.md && git commit -m 'docs: tick y'"
guard 0 "$r" "git add -A && git commit -m 'docs: plan'"

case="Repository opted out"
r="$(repo main)"; change "$r" x approved; echo y >"$r/a.txt"; git -C "$r" add openspec a.txt
git -C "$r" config solo.allowMainCommits true
guard 0 "$r" "git commit -m m"
git -C "$r" config solo.allowMainCommits false
guard 2 "$r" "git commit -m m"

case="Other commands pass"
r="$(repo main)"; change "$r" x approved; echo y >"$r/a.txt"; git -C "$r" add openspec a.txt
guard 0 "$r" "git status --short"
guard 0 "$r" "git log --oneline -1"
guard 0 "$r" "git commit-tree HEAD^{tree} -m m"
guard 0 "$r" "echo git commit is how you save"
mkdir -p "$tmp/plain"
guard 0 "$tmp/plain" "git commit -m m"
guard 0 "$tmp/does-not-exist" "git commit -m m"

case="Guard fault lets the command run"
rc=0; echo 'not json' | bash "$G" >/dev/null 2>&1 || rc=$?
[ "$rc" -ne 2 ] || fail "unparsable input blocked the command"
rc=0; printf '' | bash "$G" >/dev/null 2>&1 || rc=$?
[ "$rc" -ne 2 ] || fail "empty input blocked the command"
# A guard that cannot find its tools must not block either.
bare="$tmp/bare"; mkdir -p "$bare"
for t in bash cat dirname; do ln -sf "$(command -v "$t")" "$bare/$t"; done
ev="$(jq -n --arg cwd "$r" '{cwd: $cwd, tool_name: "Bash", tool_input: {command: "git commit -m m"}}')"
rc=0; PATH="$bare" bash "$G" <<<"$ev" >/dev/null 2>&1 || rc=$?
[ "$rc" -ne 2 ] || fail "a guard without jq blocked the command"
# jq present, then rg or git missing: still never a block.
for drop in rg git; do
  for t in jq rg git sed; do [ "$t" = "$drop" ] || ln -sf "$(command -v "$t")" "$bare/$t"; done
  rm -f "$bare/$drop"
  rc=0; PATH="$bare" bash "$G" <<<"$ev" >/dev/null 2>&1 || rc=$?
  [ "$rc" -ne 2 ] || fail "a guard without $drop blocked the command"
done

echo "commit-guard.test.sh: ok"
