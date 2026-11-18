#!/usr/bin/env bash
# Usage: review-md.sh [--base <ref>]
# Prints the root REVIEW.md and the nearest REVIEW.md above each file changed since the merge
# base with <ref> (default origin/main), committed or not, plus untracked files. Every REVIEW.md
# is read from the base ref with git show, never from the working tree, so a branch cannot
# loosen the rules it is reviewed by.
# Output: each file as a `== <path> ==` line, then its text; nothing when the base has none.
# Exit 1 on an unknown ref or a base with no history in common, 2 on bad usage.
set -euo pipefail
base=origin/main
if [ "${1:-}" = --base ]; then
  base="${2:?usage: review-md.sh [--base <ref>]}"
  shift 2
fi
[ $# -eq 0 ] || { echo "usage: review-md.sh [--base <ref>]" >&2; exit 2; }
git rev-parse --verify --quiet "$base^{commit}" >/dev/null || { echo "review-md.sh: unknown ref $base" >&2; exit 1; }
# Outside the process substitution below, where a failure would not stop the script.
mb="$(git merge-base "$base" HEAD)" || { echo "review-md.sh: $base and HEAD share no history" >&2; exit 1; }
top="$(git rev-parse --show-toplevel)"
mapfile -d '' -t paths < <(git -C "$top" diff -z --name-only "$mb"; git -C "$top" ls-files -z --others --exclude-standard)

declare -A seen
for path in "" "${paths[@]}"; do
  dir="$path"
  while :; do
    dir="$(dirname -- "$dir")"
    if [ "$dir" = . ]; then file=REVIEW.md; else file="$dir/REVIEW.md"; fi
    if [ -z "${seen[$file]:-}" ] && text="$(git show "$base:$file" 2>/dev/null)"; then
      seen[$file]=1
      printf '== %s ==\n%s\n' "$file" "$text"
    fi
    # The nearest REVIEW.md per path wins; the root one is printed first, for the "" entry.
    [[ -n "${seen[$file]:-}" || "$dir" == . ]] && break
  done
done
