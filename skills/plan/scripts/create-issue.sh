#!/usr/bin/env bash
# Usage: create-issue.sh <slug> [--dry-run]
# On approval: creates the change's tracking issue, then sets Status: approved and Issue: owner/repo#n.
# Title = first What Changes item; body = the proposal's Why and What Changes plus the change path;
# label type:bug|feat|chore from the slug prefix; assigned to @me. A proposal that already names
# an issue is only approved. --dry-run prints the writes and the status update instead.
set -euo pipefail
usage() { echo "usage: create-issue.sh <slug> [--dry-run]" >&2; exit 2; }
slug="${1:-}" dry=""
case "${2:-}" in "") ;; --dry-run) dry=1 ;; *) usage ;; esac
[ $# -le 2 ] || usage
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$here/common.sh"
slug_ok "$slug"
prop="openspec/changes/$slug/proposal.md"
[ -f "$prop" ] || { echo "create-issue.sh: no $prop" >&2; exit 2; }
# Checked before the issue exists: a later set-status failure would make a re-run open a second issue.
# A done change is past approval; approving it again would undo that.
rg -q '^Status: (draft|approved)\s*$' "$prop" || { echo "create-issue.sh: $prop needs Status: draft or approved" >&2; exit 1; }
issue="$(issue_of "$prop")"
if [ -n "$issue" ] && rg -q '^Status: approved\s*$' "$prop"; then
  echo "create-issue.sh: $slug already approved, Issue: $issue"
  exit 0
fi

if [ -z "$issue" ]; then
  title="$(awk '/^## /{on = ($0 == "## What Changes"); next} on && /^- /{sub(/^- /, ""); print; exit}' "$prop")"
  [ -n "$title" ] || { echo "create-issue.sh: no '- ' item under ## What Changes in $prop" >&2; exit 1; }
  case "$slug" in fix-*) kind=bug ;; add-*) kind=feat ;; *) kind=chore ;; esac
  body="$(mktemp)"
  trap 'rm -f "$body"' EXIT
  # The proposal stays the source; the body lets contributors without the change folder see the plan.
  awk '/^## /{on = ($0 == "## Why" || $0 == "## What Changes")} on' "$prop" >"$body"
  printf '\nChange: openspec/changes/%s/\n' "$slug" >>"$body"
  ensure_label "$kind"
  args=(gh issue create --title "$title" --body-file "$body" --label "type:$kind" --assignee @me)
  if [ -n "$dry" ]; then
    write "${args[@]}"
    issue="<owner/repo#n>"
  else
    url="$("${args[@]}")"
    [[ "$url" =~ ^https://[^/]+/([^/]+/[^/]+)/issues/([0-9]+)$ ]] || { echo "create-issue.sh: gh did not return an issue URL: $url" >&2; exit 1; }
    issue="${BASH_REMATCH[1]}#${BASH_REMATCH[2]}"
  fi
fi

if [ -n "$dry" ]; then
  echo "set-status.sh $slug approved $issue"
else
  "$here/set-status.sh" "$slug" approved "$issue"
fi
