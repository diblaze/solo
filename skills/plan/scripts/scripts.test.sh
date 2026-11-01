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
# gh: logs each call, answers from STUB_* env, keeps the last --body-file at $GH_LOG.body.
cat >"$stub/gh" <<'EOF'
#!/usr/bin/env bash
echo "$*" >>"$GH_LOG"
prev=""; for a in "$@"; do [ "$prev" != --body-file ] || cp "$a" "$GH_LOG.body"; prev="$a"; done
case "$1 $2" in
  "issue view") if [[ "$*" == *--jq* ]]; then printf '%s\n' "${STUB_ISSUE_LINES-}"; else printf '%s\n' "${STUB_ISSUE_JSON-}"; fi ;;
  "issue create") echo "${STUB_ISSUE_URL-}" ;;
  "label list") [ -z "${STUB_LABELS:-}" ] || echo "$STUB_LABELS" ;;
  api\ repos/*/collaborators/*) [[ " ${STUB_COLLABS-} " == *" ${2##*/} "* ]] || exit 1 ;;
esac
EOF
chmod +x "$stub/openspec" "$stub/npx" "$stub/gh"
export PATH="$stub:$PATH" GH_LOG="$tmp/gh.log"

fail() { echo "FAIL: $case: $*" >&2; exit 1; }
# fails <rc> <cmd…>: run cmd, keep stdout/stderr in $tmp/out, $tmp/err, assert its exit code.
fails() {
  local want="$1" rc=0; shift
  "$@" >"$tmp/out" 2>"$tmp/err" || rc=$?
  [ "$rc" -eq "$want" ] || fail "exit $rc, want $want: $* (stderr: $(cat "$tmp/err"))"
}
newrepo() {
  case="$1"; : >"$LOG"; : >"$GH_LOG"; rm -f "$GH_LOG.body"
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

# mkprop <slug> <issue-line> [item…]: a committed draft proposal with Why, What Changes items and Impact.
mkprop() {
  local slug="$1" issue="$2"; shift 2
  mkdir -p "openspec/changes/$slug"
  { printf '# Proposal\n\nStatus: draft\n%s\n\n## Why\nNeed x.\n\n## What Changes\n' "$issue"
    [ $# -eq 0 ] || printf '%s\n' "$@"
    printf '\n## Impact\nNone.\n'; } >"openspec/changes/$slug/proposal.md"
  git add -A && git commit -q -m "add $slug"
}

# Traversal slug refused / Flag-like slug refused
for slug in '../../x' '--help'; do
  newrepo "slug $slug"
  for cmd in "$S/new-change.sh $slug" "$S/validate-change.sh $slug" "$S/set-status.sh $slug draft" "$FOLD $slug" "$S/create-issue.sh $slug"; do
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
fails 1 "$S/set-status.sh" w "done"
rg -q tasks.md "$tmp/err" || fail "stderr lacks tasks.md: $(cat "$tmp/err")"
rg -qx 'Status: approved' openspec/changes/w/proposal.md || fail "status changed"

# Fold without tasks.md refused
newrepo "Fold without tasks.md refused"
mk w "done" 'Issue: none'
head="$(git rev-parse HEAD)"
fails 1 "$FOLD" w
rg -q tasks.md "$tmp/err" || fail "stderr lacks tasks.md: $(cat "$tmp/err")"
! rg -q archive "$LOG" || fail "archive ran"
[ "$(git rev-parse HEAD)" = "$head" ] || fail "HEAD moved"

# Fold closes owner/repo issue
newrepo "Fold closes owner/repo issue"
mk f "done" 'Issue: o/r#12' tasks
fails 0 "$FOLD" f
git log -1 --format=%B | rg -qF 'Closes o/r#12' || fail "fold commit: $(git log -1 --format=%B)"

# Fold without issue
newrepo "Fold without issue"
mk g "done" 'Issue: none' tasks
fails 0 "$FOLD" g
! git log -1 --format=%B | rg -q Closes || fail "fold commit has Closes"

# Fold refuses a tracked change
newrepo "Fold refuses a tracked change"
mk t "done" 'Issue: none' tasks
head="$(git rev-parse HEAD)"
echo edit >>openspec/specs/.gitkeep
fails 1 "$FOLD" t
rg -q 'tree' "$tmp/err" || fail "stderr lacks tree: $(cat "$tmp/err")"
! rg -q archive "$LOG" || fail "archive ran"
[ "$(git rev-parse HEAD)" = "$head" ] || fail "HEAD moved"

# Fold refuses an untracked spec file
newrepo "Fold refuses an untracked spec file"
mk u "done" 'Issue: none' tasks
head="$(git rev-parse HEAD)"
touch openspec/changes/u/notes.md
fails 1 "$FOLD" u
rg -qF 'notes.md' "$tmp/err" || fail "stderr lacks notes.md: $(cat "$tmp/err")"
! rg -q archive "$LOG" || fail "archive ran"
[ "$(git rev-parse HEAD)" = "$head" ] || fail "HEAD moved"

# Fold ignores an unrelated untracked file
newrepo "Fold ignores an unrelated untracked file"
mk o "done" 'Issue: none' tasks
touch notes.bak
fails 0 "$FOLD" o
! git show --name-only --format= HEAD | rg -qF notes.bak || fail "fold commit has notes.bak"

# Fold refuses a malformed Issue line
newrepo "Fold refuses a malformed Issue line"
mk m "done" 'Issue: #12' tasks
head="$(git rev-parse HEAD)"
fails 1 "$FOLD" m
rg -q 'Issue' "$tmp/err" || fail "stderr lacks Issue: $(cat "$tmp/err")"
! rg -q archive "$LOG" || fail "archive ran"
[ "$(git rev-parse HEAD)" = "$head" ] || fail "HEAD moved"

# Fold refuses a proposal without an Issue line
newrepo "Fold refuses a malformed Issue line (missing)"
mk n "done" '' tasks
fails 1 "$FOLD" n
rg -q 'Issue' "$tmp/err" || fail "stderr lacks Issue: $(cat "$tmp/err")"

# Collaborator and outsider marked
newrepo "Collaborator and outsider marked"
STUB_ISSUE_LINES=$'{"number":7}\nhttps://github.com/o/r/issues/7\nalice\nalice\nmallory' STUB_COLLABS=alice \
  fails 0 "$S/read-issue.sh" 7
[ "$(cat "$tmp/out")" = $'{"number":7}\ncollaborator alice\noutsider mallory' ] || fail "stdout: $(cat "$tmp/out")"
# One read: the printed JSON and the author list come from the same response.
[ "$(rg -c '^issue view' "$GH_LOG")" -eq 1 ] || fail "issue read more than once: $(cat "$GH_LOG")"
rg -qF 'api repos/o/r/collaborators/mallory' "$GH_LOG" || fail "mallory not looked up: $(cat "$GH_LOG")"

# Issue on another host read
newrepo "Issue on another host read"
STUB_ISSUE_LINES=$'{"number":7}\nhttps://forge.example.test/o/r/issues/7\nalice' STUB_COLLABS=alice \
  fails 0 "$S/read-issue.sh" https://forge.example.test/o/r/issues/7
[ "$(cat "$tmp/out")" = $'{"number":7}\ncollaborator alice' ] || fail "stdout: $(cat "$tmp/out")"
rg -qF 'api repos/o/r/collaborators/alice' "$GH_LOG" || fail "alice not looked up in o/r: $(cat "$GH_LOG")"

# Bad issue argument refused
newrepo "Bad issue argument refused"
for bad in '1; touch INJECTED' 0 '#0' 007 https://github.com/o/r/issues/0 https://forge.example.test/o/r/issues/0; do
  fails 2 "$S/read-issue.sh" "$bad"
  [ ! -s "$GH_LOG" ] || fail "$bad: gh called: $(cat "$GH_LOG")"
done
[ -z "$(find "$tmp" -name INJECTED)" ] || fail "INJECTED was created"

# Issue created on approval
newrepo "Issue created on approval"
mkprop add-x 'Issue: none' '- Add x' '- Document x'
STUB_ISSUE_URL=https://github.com/o/r/issues/5 STUB_LABELS=type:feat fails 0 "$S/create-issue.sh" add-x
rg -qx 'issue create --title Add x --body-file \S+ --label type:feat --assignee @me' "$GH_LOG" || fail "gh calls: $(cat "$GH_LOG")"
[ "$(rg -c 'issue create' "$GH_LOG")" -eq 1 ] || fail "issue create count: $(cat "$GH_LOG")"
for l in '## Why' 'Need x.' '## What Changes' '- Add x' '- Document x'; do rg -qxF -- "$l" "$GH_LOG.body" || fail "body lacks $l: $(cat "$GH_LOG.body")"; done
! rg -qF 'Impact' "$GH_LOG.body" || fail "body has Impact: $(cat "$GH_LOG.body")"
[ "$(tail -n1 "$GH_LOG.body")" = 'Change: openspec/changes/add-x/' ] || fail "body end: $(tail -n1 "$GH_LOG.body")"
rg -qx 'Status: approved' openspec/changes/add-x/proposal.md || fail "status not approved"
rg -qx 'Issue: o/r#5' openspec/changes/add-x/proposal.md || fail "issue not recorded"

# Change already tracked
newrepo "Change already tracked"
mkprop add-y 'Issue: o/r#3' '- Add y'
fails 0 "$S/create-issue.sh" add-y
! rg -q 'issue create' "$GH_LOG" || fail "issue created: $(cat "$GH_LOG")"
rg -qx 'Status: approved' openspec/changes/add-y/proposal.md || fail "status not approved"
rg -qx 'Issue: o/r#3' openspec/changes/add-y/proposal.md || fail "issue changed"

# Finished change refused
newrepo "Finished change refused"
mkprop add-d 'Issue: o/r#3' '- Add d'
sed -i 's/^Status: draft$/Status: done/' openspec/changes/add-d/proposal.md
cp openspec/changes/add-d/proposal.md "$tmp/before"
fails 1 "$S/create-issue.sh" add-d
rg -q 'Status' "$tmp/err" || fail "stderr lacks Status: $(cat "$tmp/err")"
cmp -s "$tmp/before" openspec/changes/add-d/proposal.md || fail "proposal changed"
[ ! -s "$GH_LOG" ] || fail "gh called: $(cat "$GH_LOG")"

# Approved change re-run
newrepo "Approved change re-run"
mkprop add-a 'Issue: o/r#3' '- Add a'
sed -i 's/^Status: draft$/Status: approved/' openspec/changes/add-a/proposal.md
cp openspec/changes/add-a/proposal.md "$tmp/before"
fails 0 "$S/create-issue.sh" add-a
cmp -s "$tmp/before" openspec/changes/add-a/proposal.md || fail "proposal changed"
[ ! -s "$GH_LOG" ] || fail "gh called: $(cat "$GH_LOG")"

# No What Changes line refused
newrepo "No What Changes line refused"
mkprop add-z 'Issue: none'
fails 1 "$S/create-issue.sh" add-z
rg -qF 'What Changes' "$tmp/err" || fail "stderr lacks What Changes: $(cat "$tmp/err")"
! rg -q 'issue create' "$GH_LOG" || fail "issue created"
rg -qx 'Status: draft' openspec/changes/add-z/proposal.md || fail "status changed"

# Type label follows the slug prefix
newrepo "Type label follows the slug prefix"
mkprop fix-y 'Issue: none' '- Fix y'
mkprop tidy-z 'Issue: none' '- Tidy z'
STUB_ISSUE_URL=https://github.com/o/r/issues/6 STUB_LABELS=$'type:bug\ntype:chore' fails 0 "$S/create-issue.sh" fix-y
rg -q 'issue create --title Fix y .*--label type:bug ' "$GH_LOG" || fail "fix-y: $(cat "$GH_LOG")"
# Any forge host: the issue URL is parsed host-independently.
STUB_ISSUE_URL=https://forge.example.test/o/r/issues/7 STUB_LABELS=$'type:bug\ntype:chore' fails 0 "$S/create-issue.sh" tidy-z
rg -q 'issue create --title Tidy z .*--label type:chore ' "$GH_LOG" || fail "tidy-z: $(cat "$GH_LOG")"
rg -qx 'Issue: o/r#7' openspec/changes/tidy-z/proposal.md || fail "other-host issue not recorded"
! rg -q 'label create' "$GH_LOG" || fail "label created: $(cat "$GH_LOG")"

# Issue label absent in repository
newrepo "Issue label absent in repository"
mkprop add-x 'Issue: none' '- Add x'
STUB_ISSUE_URL=https://github.com/o/r/issues/5 fails 0 "$S/create-issue.sh" add-x
rg -q '^label create type:feat ' "$GH_LOG" || fail "label not created: $(cat "$GH_LOG")"
[ "$(rg -n 'label create' "$GH_LOG" | cut -d: -f1)" -lt "$(rg -n 'issue create' "$GH_LOG" | cut -d: -f1)" ] || fail "label not created before issue"

# Approval dry run
newrepo "Approval dry run"
mkprop add-x 'Issue: none' '- Add x'
cp openspec/changes/add-x/proposal.md "$tmp/before"
STUB_LABELS=type:feat fails 0 "$S/create-issue.sh" add-x --dry-run
rg -q 'gh issue create .*--label type:feat --assignee @me' "$tmp/out" || fail "stdout: $(cat "$tmp/out")"
rg -q 'set-status\.sh add-x approved' "$tmp/out" || fail "stdout lacks set-status: $(cat "$tmp/out")"
! rg -q 'create' "$GH_LOG" || fail "write made: $(cat "$GH_LOG")"
cmp -s "$tmp/before" openspec/changes/add-x/proposal.md || fail "proposal changed"

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
for s in "$S/new-change.sh v" "$S/validate-change.sh v" "$S/set-status.sh v draft" "$FOLD v" "$S/openspec.sh --version" "$S/read-issue.sh 1" "$S/create-issue.sh v"; do
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
