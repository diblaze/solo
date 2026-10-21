#!/usr/bin/env bash
# Usage: set-status.sh <slug> <draft|approved|done> [owner/repo#n|none]
# Rewrites Status: (and Issue: when given) in proposal.md. 'done' refuses while
# tasks.md is missing or has an unticked box.
set -euo pipefail
slug="${1:?usage: set-status.sh <slug> <draft|approved|done> [issue]}"
status="${2:?usage: set-status.sh <slug> <draft|approved|done> [issue]}"
issue="${3:-}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$here/common.sh"
slug_ok "$slug"
[[ -z "$issue" || "$issue" =~ ^($ISSUE_RE|none)$ ]] || { echo "set-status.sh: issue must be owner/repo#n or none: $issue" >&2; exit 2; }
dir="openspec/changes/$slug"
[ -f "$dir/proposal.md" ] || { echo "set-status.sh: no $dir/proposal.md" >&2; exit 2; }
case "$status" in draft|approved|done) ;; *) echo "set-status.sh: bad status: $status" >&2; exit 2 ;; esac
if [ "$status" = "done" ]; then
  [ -f "$dir/tasks.md" ] || { echo "set-status.sh: no $dir/tasks.md; not done" >&2; exit 1; }
  if rg -n '^\s*- \[ ?\]' "$dir/tasks.md"; then
    echo "set-status.sh: unticked tasks above; not done" >&2
    exit 1
  fi
fi
rg -q '^Status: ' "$dir/proposal.md" || { echo "set-status.sh: proposal.md has no Status: line" >&2; exit 1; }
sed -i "s|^Status: .*|Status: $status|" "$dir/proposal.md"
[ -z "$issue" ] || sed -i "s|^Issue: .*|Issue: $issue|" "$dir/proposal.md"
rg -n '^(Status|Issue): ' "$dir/proposal.md"
