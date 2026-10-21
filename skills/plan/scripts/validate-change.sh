#!/usr/bin/env bash
# Usage: validate-change.sh <slug>
# Strict OpenSpec validation, plus: every scenario in the delta specs is named,
# in double quotes, by a task in tasks.md; and proposal.md carries Status/Issue.
set -euo pipefail
slug="${1:?usage: validate-change.sh <slug>}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$here/common.sh"
slug_ok "$slug"
dir="openspec/changes/$slug"
[ -d "$dir" ] || { echo "validate-change.sh: no $dir" >&2; exit 2; }

"$here/openspec.sh" validate "$slug" --strict --no-interactive

fail=0
rg -q '^Status: \S' "$dir/proposal.md" || { echo "✗ proposal.md: missing 'Status:' line"; fail=1; }
( issue_of "$dir/proposal.md" >/dev/null ) 2>/dev/null || { echo "✗ proposal.md: needs exactly one 'Issue: owner/repo#n' or 'Issue: none' line"; fail=1; }
[ -f "$dir/tasks.md" ] || { echo "✗ tasks.md missing"; exit 1; }
if [ -d "$dir/specs" ]; then
  while IFS= read -r name; do
    rg -qF "\"$name\"" "$dir/tasks.md" || { echo "✗ scenario \"$name\" is not named by any task in tasks.md"; fail=1; }
  done < <(rg --no-filename -o -r '$1' '^#### Scenario: (.+?)\s*$' "$dir/specs" | sort -u)
fi
[ "$fail" -eq 0 ] && echo "Change '$slug' passes scenario and header checks"
exit "$fail"
