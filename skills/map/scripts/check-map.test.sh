#!/usr/bin/env bash
# Offline tests for check-map.sh: throwaway git repos with AGENTS.md maps.
# Usage: bash skills/map/scripts/check-map.test.sh
set -euo pipefail
# Throwaway repos below must not inherit a caller's repo (git rebase --exec exports GIT_DIR).
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR GIT_PREFIX
CHECK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/check-map.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export GIT_CEILING_DIRECTORIES="$tmp"

fail() { echo "FAIL: $case: $*" >&2; exit 1; }
# fails <rc|nonzero> <cmd…>: run cmd, keep stdout/stderr in $tmp/out, $tmp/err, assert its exit code.
fails() {
  local want="$1" rc=0; shift
  "$@" >"$tmp/out" 2>"$tmp/err" || rc=$?
  if [ "$want" = nonzero ]; then [ "$rc" -ne 0 ] || fail "exit 0, want non-zero: $*"
  else [ "$rc" -eq "$want" ] || fail "exit $rc, want $want: $* (stderr: $(cat "$tmp/err"))"; fi
}
newrepo() {
  case="$1"
  cd "$(mktemp -d "$tmp/r.XXXX")"
  git init -q && git config user.email t@example.com && git config user.name t
  mkdir -p src
  printf '# repo\n\n## Coding standard\n- Check: `make check`\n- Tests: `make test`\n\n## Map\n| Directory | Purpose |\n| --- | --- |\n| [src/](src/AGENTS.md) | code |\n| [src/agents/](src/agents/AGENTS.md) | agents |\n' >AGENTS.md
  printf '<!-- Parent: ../AGENTS.md -->\n# src/\n\n## Purpose\nCode. See [main](main.sh).\n' >src/AGENTS.md
  touch src/main.sh
  mkdir -p src/agents && printf '# agents\n' >src/agents/AGENTS.md
  git add -A && git commit -q -m init
}

newrepo "Valid map passes"
fails 0 "$CHECK"
rg -q 'check-map.sh: ok' "$tmp/out" || fail "no ok line: $(cat "$tmp/out")"

newrepo "Broken link refused"
printf '<!-- Parent: ../AGENTS.md -->\n# src/\nSee [gone](missing.sh) and [web](https://example.com) and [anchor](#x).\n' >src/AGENTS.md
fails nonzero "$CHECK"
rg -q 'src/AGENTS.md' "$tmp/err" && rg -q 'missing.sh' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"
! rg -q 'example.com|#x' "$tmp/err" || fail "flagged a URL or anchor: $(cat "$tmp/err")"

newrepo "Broken link refused (Parent)"
printf '<!-- Parent: ../nope/AGENTS.md -->\n# src/\n' >src/AGENTS.md
fails nonzero "$CHECK"
rg -q 'nope/AGENTS.md' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"

for d in agents commands; do
  newrepo "Plugin definition folder refused ($d)"
  mkdir -p .claude-plugin "$d" && echo '{}' >.claude-plugin/plugin.json
  printf '# %s\n' "$d" >"$d/AGENTS.md"
  fails nonzero "$CHECK"
  rg -qF "$d/AGENTS.md" "$tmp/err" || fail "stderr: $(cat "$tmp/err")"
done

newrepo "Plugin definition folder refused (.claude/agents)"
mkdir -p .claude/agents && printf '# a\n' >.claude/agents/AGENTS.md
fails nonzero "$CHECK"
rg -qF '.claude/agents/AGENTS.md' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"

newrepo "Plugin definition folder refused (non-plugin agents/ is fine)"
mkdir -p agents && printf '# agents\n' >agents/AGENTS.md
printf '| [agents/](agents/AGENTS.md) | agents |\n' >>AGENTS.md
fails 0 "$CHECK"

newrepo "Coding standard edited refused"
sed -i 's/make check/make lint/' AGENTS.md
fails nonzero "$CHECK"
rg -q 'Coding standard' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"

newrepo "Coding standard edited refused (Map change alone is fine)"
printf '| [docs/](docs/AGENTS.md) | docs |\n' >>AGENTS.md
mkdir -p docs && printf '<!-- Parent: ../AGENTS.md -->\n# docs/\n' >docs/AGENTS.md
fails 0 "$CHECK"

newrepo "Broken link refused (title, angle and reference links)"
printf '# src/\n[a](nope1.md "t")\n[b](<no pe.md>)\n[c]: nope3.md\n' >src/AGENTS.md
fails nonzero "$CHECK"
for t in nope1.md 'no pe.md' nope3.md; do rg -qF "$t" "$tmp/err" || fail "missed $t: $(cat "$tmp/err")"; done

newrepo "Broken link refused (file:line target)"
printf '# src/\n[x](gone.sh:3)\n' >src/AGENTS.md
fails nonzero "$CHECK"
rg -qF 'gone.sh' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"

newrepo "Valid map passes (code, root-absolute and file:line links)"
printf '# src/\nInline `[label](path/to/file)` and [main](main.sh:1) and [root](/AGENTS.md).\n```\n[fenced](not/here.md)\n```\n' >src/AGENTS.md
fails 0 "$CHECK"

newrepo "Broken link refused (non-ASCII path)"
mkdir -p "å" && printf '# å/\n[x](nope.md)\n' >"å/AGENTS.md"
fails nonzero "$CHECK"

for d in commands/sub agents/sub output-styles; do
  newrepo "Plugin definition folder refused (nested $d)"
  mkdir -p .claude-plugin "$d" && echo '{}' >.claude-plugin/plugin.json
  printf '# x\n' >"$d/AGENTS.md"
  fails nonzero "$CHECK"
  rg -qF "$d/AGENTS.md" "$tmp/err" || fail "stderr: $(cat "$tmp/err")"
done

newrepo "Coding standard edited refused (typo base ref)"
fails nonzero "$CHECK" origin/mian
rg -qF 'origin/mian' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"

newrepo "Unlinked map file refused"
mkdir -p docs && printf '<!-- Parent: ../AGENTS.md -->\n# docs/\n' >docs/AGENTS.md
fails nonzero "$CHECK"
rg -qF 'docs/AGENTS.md' "$tmp/err" && rg -q 'root Map' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"

newrepo "Unlinked map file refused (no root AGENTS.md)"
git rm -q AGENTS.md
fails nonzero "$CHECK"
rg -qF 'src/AGENTS.md' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"

newrepo "Unlinked map file refused (link outside the Map section)"
mkdir -p docs && printf '# docs/\n' >docs/AGENTS.md
sed -i 's|^# repo$|# repo\nSee [docs](docs/AGENTS.md).|' AGENTS.md
fails nonzero "$CHECK"
rg -qF 'docs/AGENTS.md' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"

newrepo "Valid map passes (unnormalised Map links)"
mkdir -p docs && printf '# docs/\n' >docs/AGENTS.md
printf '| [docs/](./docs/../docs//./AGENTS.md) | docs |\n' >>AGENTS.md
fails 0 "$CHECK"

newrepo "Plugin definition folder refused (one error, no Map row asked)"
mkdir -p .claude-plugin agents && echo '{}' >.claude-plugin/plugin.json
printf '# a\n' >agents/AGENTS.md
fails nonzero "$CHECK"
! rg -q 'root Map' "$tmp/err" || fail "asked for a Map row: $(cat "$tmp/err")"

echo "check-map.test.sh: ok"
