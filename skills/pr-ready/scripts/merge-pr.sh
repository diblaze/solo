#!/usr/bin/env bash
# Usage: merge-pr.sh <n> [--dry-run]
# Rebase-merges PR n and deletes its remote branch. Refuses a draft or unmergeable PR before any
# write. Switches squash merging off first when the repo allows it, merges, then retargets open PRs
# stacked on the branch onto its base and prints the rebase and lease push each still needs, then
# deletes the branch and fast-forwards the local base when it is checked out.
# --dry-run runs every check and read-only gh call, and prints the writes instead.
set -euo pipefail
usage() { echo "usage: merge-pr.sh <n> [--dry-run]" >&2; exit 2; }
die() { echo "merge-pr.sh: $*" >&2; exit 1; }
n="${1:-}" dry=""
[[ "$n" =~ ^[1-9][0-9]*$ ]] || usage
case "${2:-}" in "") ;; --dry-run) dry=1 ;; *) usage ;; esac
[ $# -le 2 ] || usage
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../plan/scripts" && pwd)/common.sh"

pr="$(gh pr view "$n" --json state,isDraft,mergeable,mergeStateStatus,baseRefName,headRefName,headRefOid \
  --jq '.state, .isDraft, .mergeable, .mergeStateStatus, .baseRefName, .headRefName, .headRefOid')"
{ read -r state; read -r draft; read -r mergeable; read -r mstate; read -r base; read -r head; read -r oid; } <<<"$pr"
[ "$state" = OPEN ] || die "PR #$n is $state, not OPEN"
[ "$draft" != true ] || die "PR #$n is a draft; mark it ready first"
[ "$mergeable" != CONFLICTING ] || die "PR #$n is CONFLICTING with $base; rebase it first"
case "$mstate" in
  BLOCKED|DIRTY) die "PR #$n merge state is $mstate: required checks or reviews missing, or conflicts" ;;
  BEHIND) die "PR #$n merge state is BEHIND: update the branch with $base first" ;;
  UNKNOWN) die "PR #$n merge state is UNKNOWN: GitHub is still computing it; rerun in a moment" ;;
esac
settings="$(gh repo view --json nameWithOwner,squashMergeAllowed,rebaseMergeAllowed --jq '.nameWithOwner, .squashMergeAllowed, .rebaseMergeAllowed')"
{ read -r repo; read -r squash; read -r rebase; } <<<"$settings"
[ "$rebase" = true ] || die "rebase merging is disabled in this repository; enable it first"
children="$(gh pr list --base "$head" --state open --json number,headRefName --jq '.[] | "\(.number) \(.headRefName)"')"

[ "$squash" != true ] || write gh repo edit --enable-squash-merge=false
# --repo keeps gh off local branches (no checkout, no local delete). The branch is deleted below,
# so a failed merge leaves every child PR untouched.
write gh pr merge "$n" --repo "$repo" --rebase
# Retarget before the delete: deleting the head branch could close the PRs stacked on it.
while read -r c _; do [ -z "$c" ] || write gh pr edit "$c" --repo "$repo" --base "$base"; done <<<"$children"
# The rebase can conflict, so it is printed for the caller, not run.
while read -r c cb; do
  [ -z "$c" ] || echo "PR #$c next: git rebase --onto origin/$base $oid $cb && git push --force-with-lease origin $cb"
done <<<"$children"
# The PR is merged now: a branch delete or local update that fails is a warning, not a failure.
write gh api -X DELETE "repos/$repo/git/refs/heads/$head" || echo "merge-pr.sh: warning: PR #$n merged, but deleting branch $head failed" >&2
[ -z "$dry" ] || exit 0
if ! git fetch -q origin "+refs/heads/$base:refs/remotes/origin/$base"; then
  echo "merge-pr.sh: warning: PR #$n merged, but fetching $base failed" >&2
elif [ "$(git rev-parse --abbrev-ref HEAD)" = "$base" ] && ! git merge -q --ff-only "origin/$base"; then
  echo "merge-pr.sh: warning: PR #$n merged, but local $base did not fast-forward to origin/$base" >&2
fi
