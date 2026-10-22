#!/usr/bin/env bash
# Usage: check-map.sh [base-ref]   (default HEAD)
# Fails on an AGENTS.md anywhere below a plugin's or .claude/'s agents/, commands/ or
# output-styles/ folder, a relative link or Parent comment that does not resolve, a nested
# AGENTS.md that no row of the root `## Map` links, or a root
# `## Coding standard` that differs from <base-ref>. Links inside code spans and fences are
# examples and are not checked; `/x` resolves from the repo root, `file:12` checks `file`.
set -euo pipefail
base="${1:-HEAD}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../plan/scripts" && pwd)"
. "$here/common.sh"

bad=0
nested=() linked=""
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

# resolve <dir> <target>: the repo-relative path a link names, with `.`, `..` and `//` folded;
# nothing for a URL or a bare anchor.
resolve() {
  local t="$2" p x out=()
  case "$t" in *://*|mailto:*) return ;; esac
  t="${t%%#*}"
  [ -n "$t" ] || return 0
  [[ "$t" =~ ^(.+):[0-9]+(:[0-9]+)?$ ]] && t="${BASH_REMATCH[1]}"
  if [[ "$t" == /* ]]; then p="$t"; else p="$1/$t"; fi
  IFS=/ read -ra parts <<<"$p"
  for x in ${parts[@]+"${parts[@]}"}; do
    case "$x" in
      ''|.) ;;
      ..) if [ ${#out[@]} -gt 0 ] && [ "${out[${#out[@]}-1]}" != .. ]; then unset "out[$((${#out[@]}-1))]"; out=(${out[@]+"${out[@]}"}); else out+=(..); fi ;;
      *) out+=("$x") ;;
    esac
  done
  [ ${#out[@]} -gt 0 ] || { echo .; return; }
  (IFS=/; echo "${out[*]}")
}
# section <name>: the lines from heading `## <name>` to the next `## ` heading.
section() { awk -v h="## $1" 'index($0, h) == 1 {p=1; print; next} p && /^## /{exit} p'; }

while IFS= read -r -d '' f; do
  [ -f "$f" ] || continue
  dir="$(dirname "$f")"
  d="$dir" def=""
  while [ "$d" != . ]; do
    p="$(dirname "$d")"
    case "$(basename "$d")" in
      agents|commands|output-styles)
        if [ -f "$p/.claude-plugin/plugin.json" ] || [ "$(basename "$p")" = .claude ]; then
          err "$f: Claude Code reads every file below $(basename "$d")/ as a definition; no AGENTS.md here"
          def=1
          break
        fi ;;
    esac
    d="$p"
  done
  [ "$f" = AGENTS.md ] || [ -n "$def" ] || nested+=("$f")
  while IFS= read -r t; do
    path="$(resolve "$dir" "$t")"
    [ -z "$path" ] || [ -e "$path" ] || err "$f: link target $t does not exist"
  done < <(targets "$f")
done < <(git ls-files -z -co --exclude-standard -- AGENTS.md '*/AGENTS.md')

# Coverage: every nested file needs a row in the root `## Map` section that links it.
if [ -f AGENTS.md ]; then
  while IFS= read -r t; do linked+="$(resolve . "$t")"$'\n'; done < <(section Map <AGENTS.md | targets /dev/stdin)
fi
for f in ${nested[@]+"${nested[@]}"}; do
  rg -qxF -- "$f" <<<"$linked" || err "$f: no root Map row links it (link the file, not its directory)"
done

if git rev-parse -q --verify HEAD >/dev/null; then
  git rev-parse -q --verify "$base^{commit}" >/dev/null || { echo "check-map.sh: unknown base ref $base" >&2; exit 2; }
  old="$(git show "$base:AGENTS.md" 2>/dev/null | section 'Coding standard' || true)"
  if [ -n "$old" ]; then
    new="$( [ -f AGENTS.md ] && section 'Coding standard' <AGENTS.md || true)"
    [ "$old" = "$new" ] || err "AGENTS.md: ## Coding standard differs from $base; a map must not change it"
  fi
fi

[ "$bad" -eq 0 ] || exit 1
echo "check-map.sh: ok"
