#!/usr/bin/env bash
# Usage: open-pr.sh <base> --title <t> --body-file <f> [--dry-run]   (clean tree, on the PR branch)
# Pushes the branch and opens its PR labelled type:feat|bug|chore (from the commit
# subjects) and assigned to @me, or updates the branch's open PR. Prints the PR URL.
# --dry-run runs every check and read-only gh call, and prints the writes instead.
set -euo pipefail
usage() { echo "usage: open-pr.sh <base> --title <t> --body-file <f> [--dry-run]" >&2; exit 2; }
die() { echo "open-pr.sh: $*" >&2; exit 1; }

base="" title="" body="" dry=""
while [ $# -gt 0 ]; do
  case "$1" in
    --title) [ $# -ge 2 ] || usage; title="$2"; shift 2 ;;
    --body-file) [ $# -ge 2 ] || usage; body="$2"; shift 2 ;;
    --dry-run) dry=1; shift ;;
    -*) usage ;;
    *) [ -z "$base" ] || usage; base="$1"; shift ;;
  esac
done
if [ -z "$base" ] || [ -z "$title" ] || [ -z "$body" ]; then usage; fi
[ -f "$body" ] || die "no body file $body"
body="$(cd "$(dirname "$body")" && pwd)/$(basename "$body")"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../plan/scripts" && pwd)/common.sh"

branch="$(git rev-parse --abbrev-ref HEAD)"
[ "$branch" != "$base" ] || die "on the base branch $base; switch to the PR branch"
git fetch -q origin "+refs/heads/$base:refs/remotes/origin/$base" || die "cannot fetch $base from origin"
ref="origin/$base"
[ "$(git rev-list --count "$ref..HEAD")" -gt 0 ] || die "no commits ahead of $ref"
[ -z "$(git status --porcelain)" ] || die "working tree not clean"

subjects="$(git log --format=%s "$ref..HEAD")"
if rg -q '^feat(\([^)]*\))?!?:' <<<"$subjects"; then kind=feat
elif rg -q '^fix(\([^)]*\))?!?:' <<<"$subjects"; then kind=bug
else kind=chore; fi
label="type:$kind"

while IFS= read -r proposal; do
  [ -n "$proposal" ] || continue
  issue="$(issue_of "$proposal")"
  [ -z "$issue" ] || rg -qwF "Closes $issue" "$body" || die "body lacks 'Closes $issue' (from $proposal)"
done < <(git diff --name-only --diff-filter=A "$ref...HEAD" -- 'openspec/changes/archive/*/proposal.md')

write() { if [ -n "$dry" ]; then printf '%q ' "$@"; echo; else "$@" >/dev/null; fi; }

if ! gh label list --search "$label" --json name --jq '.[].name' | rg -qxF "$label"; then
  case "$kind" in feat) color=0052CC ;; bug) color=0E8A16 ;; chore) color=E99695 ;; esac
  write gh label create "$label" --color "$color" --description "Conventional commit type: $kind"
fi

n="$(gh pr list --head "$branch" --json number --jq '.[0].number // empty')"
# History is rewritten before a PR opens (fixup, autosquash), so every push is a lease push.
write git push -q --force-with-lease -u origin HEAD
if [ -n "$n" ]; then
  stale=()
  while IFS= read -r l; do
    [ -z "$l" ] || [ "$l" = "$label" ] || stale+=(--remove-label "$l")
  done < <(gh pr view "$n" --json labels --jq '.labels[].name | select(startswith("type:"))')
  write gh pr edit "$n" --base "$base" --title "$title" --body-file "$body" --add-label "$label" ${stale[@]+"${stale[@]}"} --add-assignee @me
else
  write gh pr create --base "$base" --title "$title" --body-file "$body" --label "$label" --assignee @me
fi
# The URL comes from pr view, not create/edit stdout, so it is exactly one line.
[ -n "$dry" ] || gh pr view ${n:+"$n"} --json url --jq .url
