#!/usr/bin/env bash
# Usage: fold.sh <slug>   (run at repo root, clean tree, on the PR branch)
# Folds the change's delta specs into openspec/specs/, archives the change and
# commits the result as `docs(spec): fold <slug>`.
set -euo pipefail
slug="${1:?usage: fold.sh <slug>}"
os="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../plan/scripts" && pwd)/openspec.sh"
dir="openspec/changes/$slug"
[ -d "$dir" ] || { echo "fold.sh: no $dir" >&2; exit 2; }
[ -z "$(git status --porcelain)" ] || { echo "fold.sh: working tree not clean; commit or fold fixes first" >&2; exit 1; }

if rg -n '^\s*- \[ ?\]' "$dir/tasks.md"; then
  echo "fold.sh: unticked tasks above; archive --yes would not catch them" >&2
  exit 1
fi
rg -q '^Status: done$' "$dir/proposal.md" || { echo "fold.sh: Status is not done in $dir/proposal.md" >&2; exit 1; }
issue="$(rg -o -r '$1' '^Issue: .*#([0-9]+)\s*$' "$dir/proposal.md" || true)"

"$os" validate "$slug" --strict --no-interactive

args=("$slug" --yes)
if rg -q '^skip_specs:\s*true' "$dir/.openspec.yaml"; then args+=(--skip-specs); fi
"$os" archive "${args[@]}"

if [ -n "$(find openspec/specs -name spec.md -print -quit 2>/dev/null)" ]; then
  "$os" validate --specs --strict --no-interactive
fi

git add -A openspec
msg=(-m "docs(spec): fold $slug")
[ -z "$issue" ] || msg+=(-m "Closes #$issue")
git commit -q "${msg[@]}"
git show --stat --format='%h %s' HEAD -- openspec
