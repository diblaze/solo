#!/usr/bin/env bash
# Usage: check-map.sh [base-ref]   (default HEAD)
# Fails on an AGENTS.md anywhere below a plugin's or .claude/'s agents/, commands/ or
# output-styles/ folder, a relative link or Parent comment that does not resolve, or a root
# `## Coding standard` that differs from <base-ref>. Links inside code spans and fences are
# examples and are not checked; `/x` resolves from the repo root, `file:12` checks `file`.
set -euo pipefail
base="${1:-HEAD}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../plan/scripts" && pwd)"
. "$here/common.sh"

bad=0
err() { echo "check-map.sh: $*" >&2; bad=1; }

# Link targets: inline `](x)`, `](x "title")`, `](<x y>)`, reference `[id]: x`, and the Parent comment.
targets() {
  local text
  text="$(awk '/^[[:space:]]*```/{f=!f; next} !f' "$1" | sed 's/`[^`]*`//g')"
  rg -o -r '$1' '\]\(\s*<([^>]+)>' <<<"$text" || true
  rg -o -r '$1' '\]\(\s*([^)<\s]+)(?:\s+"[^"]*")?\s*\)' <<<"$text" || true
  rg -o -r '$1' '^\s*\[[^\]]+\]:\s*<?([^\s>]+)>?' <<<"$text" || true
  rg -o -r '$1' '<!-- Parent: (\S+) -->' "$1" || true
}

while IFS= read -r -d '' f; do
  [ -f "$f" ] || continue
  dir="$(dirname "$f")"
  d="$dir"
  while [ "$d" != . ]; do
    p="$(dirname "$d")"
    case "$(basename "$d")" in
      agents|commands|output-styles)
        if [ -f "$p/.claude-plugin/plugin.json" ] || [ "$(basename "$p")" = .claude ]; then
          err "$f: Claude Code reads every file below $(basename "$d")/ as a definition; no AGENTS.md here"
          break
        fi ;;
    esac
    d="$p"
  done
  while IFS= read -r t; do
    case "$t" in *://*|mailto:*) continue ;; esac
    t="${t%%#*}"
    [[ "$t" =~ ^(.+):[0-9]+(:[0-9]+)?$ ]] && t="${BASH_REMATCH[1]}"
    if [[ "$t" == /* ]]; then path=".$t"; else path="$dir/$t"; fi
    [ -e "$path" ] || err "$f: link target $t does not exist"
  done < <(targets "$f")
done < <(git ls-files -z -co --exclude-standard -- AGENTS.md '*/AGENTS.md')

# The section from its heading to the next `## ` heading; $(...) drops trailing blank lines.
standard() { awk '/^## Coding standard/{p=1; print; next} p && /^## /{exit} p'; }
if git rev-parse -q --verify HEAD >/dev/null; then
  git rev-parse -q --verify "$base^{commit}" >/dev/null || { echo "check-map.sh: unknown base ref $base" >&2; exit 2; }
  old="$(git show "$base:AGENTS.md" 2>/dev/null | standard || true)"
  if [ -n "$old" ]; then
    new="$( [ -f AGENTS.md ] && standard <AGENTS.md || true)"
    [ "$old" = "$new" ] || err "AGENTS.md: ## Coding standard differs from $base; a map must not change it"
  fi
fi

[ "$bad" -eq 0 ] || exit 1
echo "check-map.sh: ok"
