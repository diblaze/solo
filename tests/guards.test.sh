#!/usr/bin/env bash
# Static checks that the skill and agent text keeps solo's guards.
# Usage: bash plugins/solo/tests/guards.test.sh
set -euo pipefail
P="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $case: $*" >&2; exit 1; }
# section <file> <from> [to]: the lines from heading "## <from>" up to "## <to>" (or the end).
section() {
  if [ -n "${3:-}" ]; then sed -n "/^## $2/,/^## $3/p" "$1"; else sed -n "/^## $2/,\$p" "$1"; fi
}
has() { rg -q -- "$2" <<<"$1" || fail "missing /$2/"; }

pr="$P/skills/pr-ready/SKILL.md"

case="Push and PR open ask first"
! rg -q '^allowed-tools:' "$pr" || fail "pr-ready pre-approves tools"
s5="$(section "$pr" 5 6)"
has "$s5" 'open-pr\.sh.*--dry-run'
has "$s5" 'AskUserQuestion'
has "$s5" 'only on yes'

case="Merge asks first"
s6="$(section "$pr" 6)"
ask="$(rg -n -m1 AskUserQuestion <<<"$s6" | cut -d: -f1)"
merge="$(rg -n -m1 'gh pr merge' <<<"$s6" | cut -d: -f1)"
[ -n "$ask" ] && [ -n "$merge" ] && [ "$ask" -lt "$merge" ] || fail "no AskUserQuestion before gh pr merge"

echo "guards.test.sh: ok"
