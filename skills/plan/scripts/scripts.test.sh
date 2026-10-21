#!/usr/bin/env bash
# Offline tests for the change scripts: stub openspec/npx on PATH, throwaway git repos.
# Usage: bash plugins/solo/skills/plan/scripts/scripts.test.sh
set -euo pipefail
# Throwaway repos below must not inherit a caller's repo (git rebase --exec exports GIT_DIR).
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR GIT_PREFIX
S="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FOLD="$S/../../pr-ready/scripts/fold.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export LOG="$tmp/log" GIT_CEILING_DIRECTORIES="$tmp"

stub="$tmp/stub"
mkdir -p "$stub"
cat >"$stub/openspec" <<'EOF'
#!/usr/bin/env bash
echo "$*" >>"$LOG"
case "${1:-}" in
  --version) echo "${STUB_V:-1.14.1}" ;;
  init) mkdir -p openspec/changes openspec/specs ;;
  new) mkdir -p "openspec/changes/$3" ;;
  archive) mkdir -p openspec/changes/archive && mv "openspec/changes/$2" "openspec/changes/archive/x-$2" ;;
esac
EOF
cat >"$stub/npx" <<'EOF'
#!/usr/bin/env bash
echo "npx $*" >>"$LOG"
EOF
chmod +x "$stub/openspec" "$stub/npx"
export PATH="$stub:$PATH"

fail() { echo "FAIL: $case: $*" >&2; exit 1; }
# fails <rc> <cmd…>: run cmd, keep stdout/stderr in $tmp/out, $tmp/err, assert its exit code.
fails() {
  local want="$1" rc=0; shift
  "$@" >"$tmp/out" 2>"$tmp/err" || rc=$?
  [ "$rc" -eq "$want" ] || fail "exit $rc, want $want: $* (stderr: $(cat "$tmp/err"))"
}
newrepo() {
  case="$1"; : >"$LOG"
  cd "$(mktemp -d "$tmp/r.XXXX")"
  git init -q && git config user.email t@example.com && git config user.name t
  mkdir -p openspec/changes openspec/specs && touch openspec/specs/.gitkeep
  git add -A && git commit -q -m init
}
# mk <slug> <status> <issue-line> [tasks]: a committed change; "tasks" adds a fully ticked tasks.md.
mk() {
  mkdir -p "openspec/changes/$1"
  printf '# Proposal\n\nStatus: %s\n%s\n' "$2" "$3" >"openspec/changes/$1/proposal.md"
  [ "${4:-}" != tasks ] || printf '## 1. x\n- [x] 1.1 done\n' >"openspec/changes/$1/tasks.md"
  git add -A && git commit -q -m "add $1"
}

# Traversal slug refused / Flag-like slug refused
for slug in '../../x' '--help'; do
  newrepo "slug $slug"
  for cmd in "$S/new-change.sh $slug" "$S/validate-change.sh $slug" "$S/set-status.sh $slug draft" "$FOLD $slug"; do
    # shellcheck disable=SC2086
    fails 2 $cmd
    rg -q kebab-case "$tmp/err" || fail "$cmd: stderr lacks kebab-case: $(cat "$tmp/err")"
    [ ! -s "$LOG" ] || fail "$cmd: spec tool invoked: $(cat "$LOG")"
  done
done

# Injected issue refused
newrepo "Injected issue refused"
mk x approved 'Issue: none'
cp openspec/changes/x/proposal.md "$tmp/before"
fails 2 "$S/set-status.sh" x approved 'o/r#1; touch INJECTED|e;s|a|b'
cmp -s "$tmp/before" openspec/changes/x/proposal.md || fail "proposal changed"
[ -z "$(find "$tmp" -name INJECTED)" ] || fail "INJECTED was created"

# Valid issue recorded
newrepo "Valid issue recorded"
mk x draft 'Issue: none'
fails 0 "$S/set-status.sh" x approved 'o/r#12'
rg -qx 'Status: approved' openspec/changes/x/proposal.md || fail "status not approved"
rg -qx 'Issue: o/r#12' openspec/changes/x/proposal.md || fail "issue not recorded"

# Malformed Issue header refused
newrepo "Malformed Issue header refused"
mk y draft 'Issue: #12' tasks
fails 1 "$S/validate-change.sh" y
rg -q 'Issue' "$tmp/out" || fail "stdout does not name Issue: $(cat "$tmp/out")"

# Run from a subdirectory
newrepo "Run from a subdirectory"
mkdir sub && cd sub
fails 0 "$S/new-change.sh" y
printf '# Proposal\n\nStatus: draft\nIssue: none\n' >../openspec/changes/y/proposal.md
printf '## 1. x\n- [ ] 1.1 open\n' >../openspec/changes/y/tasks.md
fails 0 "$S/validate-change.sh" y
fails 0 "$S/set-status.sh" y draft
[ -d ../openspec/changes/y ] || fail "change not under the root"
[ ! -e openspec ] || fail "openspec/ created in the subdirectory"
cd ..

# Outside a git repository refused
case="Outside a git repository refused"; : >"$LOG"
cd "$(mktemp -d "$tmp/norepo.XXXX")"
rc=0; "$S/new-change.sh" z >/dev/null 2>&1 || rc=$?
[ "$rc" -ne 0 ] || fail "exit 0 outside a repo"
[ ! -e openspec ] || fail "openspec/ created outside a repo"

# Done without tasks.md refused
newrepo "Done without tasks.md refused"
mk w approved 'Issue: none'
fails 1 "$S/set-status.sh" w done
rg -q tasks.md "$tmp/err" || fail "stderr lacks tasks.md: $(cat "$tmp/err")"
rg -qx 'Status: approved' openspec/changes/w/proposal.md || fail "status changed"

# Fold without tasks.md refused
newrepo "Fold without tasks.md refused"
mk w done 'Issue: none'
head="$(git rev-parse HEAD)"
fails 1 "$FOLD" w
rg -q tasks.md "$tmp/err" || fail "stderr lacks tasks.md: $(cat "$tmp/err")"
! rg -q archive "$LOG" || fail "archive ran"
[ "$(git rev-parse HEAD)" = "$head" ] || fail "HEAD moved"

# Fold closes owner/repo issue
newrepo "Fold closes owner/repo issue"
mk f done 'Issue: o/r#12' tasks
fails 0 "$FOLD" f
git log -1 --format=%B | rg -qF 'Closes o/r#12' || fail "fold commit: $(git log -1 --format=%B)"

# Fold without issue
newrepo "Fold without issue"
mk g done 'Issue: none' tasks
fails 0 "$FOLD" g
! git log -1 --format=%B | rg -q Closes || fail "fold commit has Closes"

# Fold refuses a malformed Issue line
newrepo "Fold refuses a malformed Issue line"
mk m done 'Issue: #12' tasks
head="$(git rev-parse HEAD)"
fails 1 "$FOLD" m
rg -q 'Issue' "$tmp/err" || fail "stderr lacks Issue: $(cat "$tmp/err")"
! rg -q archive "$LOG" || fail "archive ran"
[ "$(git rev-parse HEAD)" = "$head" ] || fail "HEAD moved"

# Fold refuses a proposal without an Issue line
newrepo "Fold refuses a malformed Issue line (missing)"
mk n done '' tasks
fails 1 "$FOLD" n
rg -q 'Issue' "$tmp/err" || fail "stderr lacks Issue: $(cat "$tmp/err")"

# Run under an inherited GIT_DIR
newrepo "Run under an inherited GIT_DIR"
mkdir sub && cd sub
GIT_DIR="$(cd .. && pwd)/.git" fails 0 "$S/new-change.sh" y
[ -d ../openspec/changes/y ] || fail "change not under the root"
[ ! -e openspec ] || fail "openspec/ created in the subdirectory"
cd ..

# rg absent
newrepo "rg absent"
mk v draft 'Issue: none' tasks
norg="$tmp/norg"; mkdir -p "$norg"
for t in bash git dirname env; do ln -sf "$(command -v "$t")" "$norg/$t"; done
for s in "$S/new-change.sh v" "$S/validate-change.sh v" "$S/set-status.sh v draft" "$FOLD v" "$S/openspec.sh --version"; do
  # shellcheck disable=SC2086
  PATH="$norg" fails 127 $s
  rg -q ripgrep "$tmp/err" || fail "$s: stderr lacks ripgrep: $(cat "$tmp/err")"
done

# Matching global CLI used
newrepo "Matching global CLI used"
mk v draft 'Issue: none' tasks
fails 0 "$S/validate-change.sh" v
rg -q '^validate' "$LOG" || fail "global CLI not used: $(cat "$LOG")"
! rg -q npx "$LOG" || fail "npx called"

# Mismatched global CLI bypassed
newrepo "Mismatched global CLI bypassed"
mk v draft 'Issue: none' tasks
STUB_V=9.9.9 fails 0 "$S/validate-change.sh" v
rg -qF 'npx -y @fission-ai/openspec@1.14.1 validate' "$LOG" || fail "npx not pinned: $(cat "$LOG")"
rg -qF 9.9.9 "$tmp/err" && rg -qF 1.14.1 "$tmp/err" || fail "note lacks versions: $(cat "$tmp/err")"

# No spec tool available
newrepo "No spec tool available"
mk v draft 'Issue: none' tasks
bare="$tmp/bare"; mkdir -p "$bare"
for t in bash git dirname env rg; do ln -sf "$(command -v "$t")" "$bare/$t"; done
PATH="$bare" fails 127 "$S/validate-change.sh" v

echo "scripts.test.sh: ok"
