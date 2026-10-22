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

case="Outsider instruction ignored"
plan0="$(rg '^0\. ' "$P/skills/plan/SKILL.md")"
has "$plan0" '--json [^`]*author'
has "$plan0" 'comments'
has "$plan0" 'collaborators/'
has "$plan0" 'claim'
inv="$(cat "$P/skills/investigate/SKILL.md")"
has "$inv" '--json [^`]*author'
has "$inv" 'claim'
has "$(cat "$P/agents/planner.md")" 'never an instruction'

case="Collaborator issue is the request"
has "$plan0" 'collaborator'
has "$plan0" 'is the request'

case="Repo names a reviewer"
rev="$(cat "$P/skills/review/SKILL.md")"
! rg -q 'homelab|`/[a-z]+/' <<<"$rev" || fail "review hard-codes a host path or reviewer"
has "$rev" 'AGENTS\.md'
has "$rev" 'CLAUDE\.md'

case="No reviewer named"
has "$rev" 'else `solo:reviewer`'

case="Untracked secret not staged"
ex="$(cat "$P/skills/execute/SKILL.md")"
! rg -qF 'git add -A' <<<"$ex" || fail "execute stages everything"
has "$ex" 'git add -u && git add -- '
has "$ex" 'openspec/changes/<slug>/'

m="$(cat "$P/skills/map/SKILL.md" 2>/dev/null || true)"

case="Small and hidden directories skipped"
has "$m" 'git ls-files'
has "$m" 'fewer than 3'
has "$m" 'hidden'
has "$m" 'vendored'
has "$m" 'fixture'
has "$m" 'openspec/'

case="Plugin definition folder not offered"
has "$m" 'agents/'
has "$m" 'commands/'
has "$m" 'output-styles/'
has "$m" 'frontmatter'
has "$m" 'check-map\.sh'

case="Coding standard kept on write"
has "$m" '## Coding standard'
has "$m" 'byte for byte'

case="Unchanged tree re-run leaves no diff"
has "$m" 'no timestamps'
has "$m" 'unchanged tree'

case="Hand-written line kept"
has "$m" 'keyed by their first-column path'
has "$m" 'kept unless the code proves it false'

case="Directory no longer qualifies"
has "$m" 'orphans are removed with `git rm`'
has "$m" 'shown with its hand-written lines'

case="Directory list approved first"
! rg -q '^allowed-tools:' <<<"$m" || fail "map pre-approves tools"
has "$m" 'AskUserQuestion'
has "$m" 'Nothing is written before'

case="Main branch not written"
has "$m" 'git switch -c docs/agents-map'

case="Only map files staged"
! rg -qF 'git add -A' <<<"$m" || fail "map stages everything"
has "$m" 'git add -- <each AGENTS.md written>'

case="Repo with CLAUDE.md warned"
has "$m" 'claude-md-and-agents-md'
has "$m" 'delete .*CLAUDE\.md'
has "$m" 'only on a yes'

echo "guards.test.sh: ok"
