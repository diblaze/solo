#!/usr/bin/env bash
# Usage: verify-commits.sh <base> -- <check…>
# Runs the check at every commit in <base>..HEAD, oldest first, in a throwaway detached worktree,
# so the caller's branch, index and files stay as they are. Prints `ok <sha> <subject>` per
# passing commit and stops at the first failing commit, naming it.
set -euo pipefail
usage() { echo "usage: verify-commits.sh <base> -- <check…>" >&2; exit 2; }
[ $# -ge 3 ] && [ "$2" = -- ] || usage
base="$1"
shift 2
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
# An inherited git env would point the check back at the caller's repo instead of its worktree.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR GIT_PREFIX

shas="$(git rev-list --reverse "$base..HEAD")"
[ -n "$shas" ] || { echo "verify-commits.sh: no commits ahead of $base" >&2; exit 1; }
wt="$(mktemp -d)"
# Remove only our own worktree; a repo-wide prune would also drop the caller's moved worktrees.
trap 'git worktree remove --force "$wt" >/dev/null 2>&1 || rm -rf "$wt"' EXIT
git worktree add -q --detach "$wt" HEAD
for sha in $shas; do
  git -C "$wt" checkout -q --force --detach "$sha"
  git -C "$wt" clean -fdq # untracked files from the previous run go; ignored ones (installed deps) stay
  if ! (cd "$wt" && "$@"); then
    echo "verify-commits.sh: check failed at $(git log -1 --format='%H %s' "$sha")" >&2
    exit 1
  fi
  echo "ok $(git log -1 --format='%H %s' "$sha")"
done
