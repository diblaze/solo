#!/usr/bin/env bash
# PreToolUse hook that /solo:execute registers; it stays on for the rest of the session, in every repo.
# Reads the hook event JSON on stdin. Exits 2 (blocks the Bash call, stderr goes to Claude) only for a
# `git commit` on main or master that carries an approved OpenSpec change folder together with files
# outside openspec/ — an execute slice. The folder counts when it is staged, added in the same command
# (by name, by `git add -A|--all|.` while it has changes, or by `commit -a` while it has tracked edits). A commit of only openspec/
# files (planning) passes, and so does any repo with `git config solo.allowMainCommits true`. Every other case, including any fault, exits 0 or with a non-blocking error.
set -euo pipefail
[ -n "${GIT_WORK_TREE:-}" ] || unset GIT_DIR

in="$(cat)"
cmd="$(jq -r '.tool_input.command // empty' <<<"$in" 2>/dev/null)" || exit 0
cwd="$(jq -r '.cwd // empty' <<<"$in" 2>/dev/null)" || exit 0
[ -n "$cwd" ] || exit 0

# path <word> <base>: a shell word as a directory: quotes dropped, ~ and $HOME expanded, relative to <base>.
path() {
  local p="$1"
  p="${p#[\"\']}" p="${p%[\"\']}"
  [[ "$p" == "~"* ]] && p="$HOME${p#\~}"
  [[ "$p" == '$HOME'* ]] && p="$HOME${p#\$HOME}"
  [[ "$p" == /* ]] || p="$2/$p"
  printf '%s' "$p"
}

# One segment per simple command: split on ; & | ( ) and newlines.
mapfile -t segs < <(sed -E 's/(&&|\|\||[;&|()])/\n/g' <<<"$cmd")
git_re='^[[:space:]]*((env|command|time)[[:space:]]+|[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*git[[:space:]]+(.*)$'
dir="$cwd" target="" names=() broad="" tracked=""
for seg in "${segs[@]}"; do
  if [[ "$seg" =~ ^[[:space:]]*cd[[:space:]]+([^[:space:]]+) ]]; then
    dir="$(path "${BASH_REMATCH[1]}" "$dir")"
    continue
  fi
  [[ "$seg" =~ $git_re ]] || continue
  read -ra w <<<"${BASH_REMATCH[3]}"
  # git's own options before the subcommand; -C <dir> moves the repo for this command.
  at="$dir" i=0
  while [ "$i" -lt "${#w[@]}" ] && [[ "${w[$i]}" == -* ]]; do
    case "${w[$i]}" in
      -C) at="$(path "${w[$((i + 1))]:-.}" "$dir")"; i=$((i + 2)) ;;
      -c | --git-dir | --work-tree | --namespace) i=$((i + 2)) ;;
      *) i=$((i + 1)) ;;
    esac
  done
  sub="${w[$i]:-}" args=("${w[@]:$((i + 1))}")
  case "$sub" in
    add)
      for a in "${args[@]}"; do
        case "$a" in -A | --all | . | :/) broad=1 ;; -*) ;; *) names+=("$a") ;; esac
      done ;;
    commit)
      target="$at"
      # -a, --all, or a short-option cluster holding a (-am).
      for a in "${args[@]}"; do case "$a" in --all) tracked=1 ;; --*) ;; -*a*) tracked=1 ;; esac; done ;;
  esac
done
[ -n "$target" ] || exit 0

branch="$(git -C "$target" symbolic-ref --short -q HEAD 2>/dev/null)" || exit 0
[ "$branch" = main ] || [ "$branch" = master ] || exit 0
root="$(git -C "$target" rev-parse --show-toplevel 2>/dev/null)" || exit 0
# A repository that commits approved changes straight to main opts out: git config solo.allowMainCommits true.
[ "$(git -C "$root" config --type=bool --get solo.allowMainCommits 2>/dev/null)" != true ] || exit 0
staged="$(git -C "$root" diff --cached --name-only 2>/dev/null)" || exit 0
# Code in the commit: staged outside openspec/, or added by this command (named or broad).
code=""
while IFS= read -r f; do [ -n "$f" ] && [[ "$f" != openspec/* ]] && code=1; done <<<"$staged"
for n in "${names[@]}"; do [[ "${n#./}" != openspec* ]] && code=1; done
# changed <pathspec…>: files `git add -A` (untracked too) or `commit -a` (tracked edits only) would take in.
changed() {
  if [ -n "$broad" ]; then git -C "$root" status --porcelain -- "$@" 2>/dev/null
  elif [ -n "$tracked" ]; then git -C "$root" diff --name-only -- "$@" 2>/dev/null
  fi
}
[ -z "$(changed . ':!openspec')" ] || code=1
[ -n "$code" ] || exit 0

for p in "$root"/openspec/changes/*/proposal.md; do
  [ -f "$p" ] || continue
  rg -q '^Status: approved\s*$' "$p" 2>/dev/null || continue
  d="${p#"$root"/}" d="${d%/proposal.md}" slug="${d##*/}" hit=""
  while IFS= read -r f; do [[ "$f" == "$d/"* ]] && hit=1; done <<<"$staged"
  for n in "${names[@]}"; do n="${n#[\"\']}" n="${n%[\"\']}" n="${n#./}" n="${n%/}"; [[ "$n" == "$d" || "$n" == "$d/"* || "$d" == "$n/"* ]] && hit=1; done
  [ -z "$(changed "$d")" ] || hit=1
  [ -z "$hit" ] && continue
  echo "commit-guard: this commit puts approved change $slug and its code on $branch. Branch first in its own call: git switch -c <type>/$slug, then commit." >&2
  exit 2
done
exit 0
