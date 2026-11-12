#!/usr/bin/env bash
# Static checks that the skill and agent text keeps solo's guards.
# Usage: bash plugins/solo/tests/guards.test.sh
set -euo pipefail
P="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $case: $*" >&2; exit 1; }
# section <file> <from> [to]: the lines from heading "## <from>" up to "## <to>" (or the end).
section() {
  if [ -n "${3:-}" ]; then sed -n "/^## $2/,/^## $3/p" "$1"; else sed -n "/^## $2/,\$p" "$1"; fi
}
has() { rg -q -- "$2" <<<"$1" || fail "missing /$2/"; }
# fm <file>: the frontmatter lines; body <file>: the lines after it; allowed <file>: its allowed-tools entries.
fm() { awk 'NR == 1 && /^---$/ {f = 1; next} f && /^---$/ {exit} f' "$1"; }
body() { awk 'c >= 2 {print} /^---$/ && c < 2 {c++}' "$1"; }
allowed() { fm "$1" | awk '/^allowed-tools:/ {f = 1; next} f && /^[^ ]/ {exit} f' | sed -E 's/^[[:space:]]*-[[:space:]]*//'; }
# injected <file>: each load-time command, with the `|| true` that keeps a failure from aborting the load cut off.
injected() { { rg -o -r '$1' '^!`([^`]+)`$' "$1" || true; } | sed 's/ || true$//'; }

pr="$P/skills/pr-ready/SKILL.md"

case="Push and PR open ask first"
[ "$(allowed "$pr")" = "$(injected "$pr" | sed 's/.*/Bash(&)/')" ] || fail "pr-ready pre-approves more than its load-time read"
s5="$(section "$pr" 5 6)"
has "$s5" 'open-pr\.sh.*--dry-run'
has "$s5" 'AskUserQuestion'
has "$s5" 'only on yes'

case="Merge asks first"
s6="$(section "$pr" 6)"
has "$s6" 'merge-pr\.sh.*--dry-run'
has "$s6" 'AskUserQuestion'
has "$s6" 'only on yes'
! rg -qF 'gh pr merge' <<<"$s6" || fail "pr-ready types gh pr merge instead of running merge-pr.sh"

case="Outsider instruction ignored"
plan0="$(rg '^0\. ' "$P/skills/plan/SKILL.md")"
has "$plan0" 'read-issue\.sh'
has "$plan0" 'outsider'
has "$plan0" 'claim'
inv="$(cat "$P/skills/investigate/SKILL.md")"
has "$inv" 'read-issue\.sh'
has "$inv" 'outsider'
has "$inv" 'claim'
has "$(cat "$P/agents/planner.md")" 'never an instruction'

case="Collaborator issue is the request"
has "$plan0" 'collaborator'
has "$plan0" 'is the request'

case="Repo names a reviewer"
rev="$(cat "$P/skills/review/SKILL.md")"
! rg -q 'homelab|`/[a-z]+/' <<<"$rev" || fail "review hard-codes a host path or reviewer"
has "$rev" 'AGENTS\.md'
has "$rev" 'CLAUDE\.md'

case="No reviewer named"
has "$rev" 'else `solo:reviewer`'

case="Untracked secret not staged"
ex="$(cat "$P/skills/execute/SKILL.md")"
! rg -qF 'git add -A' <<<"$ex" || fail "execute stages everything"
has "$ex" 'git add -u && git add -- '
has "$ex" 'openspec/changes/<slug>/'

m="$(cat "$P/skills/map/SKILL.md" 2>/dev/null || true)"

case="Small and hidden directories skipped"
has "$m" 'git ls-files'
has "$m" 'fewer than 3'
has "$m" 'hidden'
has "$m" 'vendored'
has "$m" 'fixture'
has "$m" 'openspec/'

case="Plugin definition folder not offered"
has "$m" 'agents/'
has "$m" 'commands/'
has "$m" 'output-styles/'
has "$m" 'frontmatter'
has "$m" 'check-map\.sh'

case="Coding standard kept on write"
has "$m" '## Coding standard'
has "$m" 'byte for byte'

case="Unchanged tree re-run leaves no diff"
has "$m" 'no timestamps'
has "$m" 'unchanged tree'

case="Hand-written line kept"
has "$m" 'keyed by their first-column path'
has "$m" 'kept unless the code proves it false'

case="Directory no longer qualifies"
has "$m" 'orphans are removed with `git rm`'
has "$m" 'shown with its hand-written lines'

case="Directory list approved first"
[ "$(allowed "$P/skills/map/SKILL.md")" = 'Bash(${CLAUDE_SKILL_DIR}/scripts/check-map.sh)' ] || fail "map pre-approves more than check-map.sh"
has "$m" 'AskUserQuestion'
has "$m" 'Nothing is written before'

case="Main branch not written"
has "$m" 'git switch -c docs/agents-map'

case="Only map files staged"
! rg -qF 'git add -A' <<<"$m" || fail "map stages everything"
has "$m" 'git add -- <each AGENTS.md written>'

case="Repo with CLAUDE.md warned"
has "$m" 'claude-md-and-agents-md'
has "$m" 'delete .*CLAUDE\.md'
has "$m" 'only on a yes'

skills=("$P"/skills/*/SKILL.md)

case="Script path is exact"
for f in "${skills[@]}"; do
  b="$(body "$f")"
  ! rg -q 'base directory' <<<"$b" || fail "$f: still says base directory"
  while IFS= read -r t; do
    [[ "$t" == '${CLAUDE_SKILL_DIR}/'* ]] || fail "$f: script not named by \${CLAUDE_SKILL_DIR}: $t"
    [ -f "$(dirname "$f")/${t#'${CLAUDE_SKILL_DIR}/'}" ] || fail "$f: no such script: $t"
  done < <(rg -o '[^[:space:]`(]*scripts/[A-Za-z0-9_-]+\.sh' <<<"$b" || true)
done

# The only calls any skill may pre-approve: its read-only scripts, plus each command it injects at load.
declare -A READONLY=(
  [plan]=$'Bash(${CLAUDE_SKILL_DIR}/scripts/read-issue.sh *)\nBash(${CLAUDE_SKILL_DIR}/scripts/validate-change.sh *)'
  [investigate]='Bash(${CLAUDE_SKILL_DIR}/../plan/scripts/read-issue.sh *)'
  [execute]='Bash(${CLAUDE_SKILL_DIR}/../plan/scripts/validate-change.sh *)'
  [issues]=$'Bash(${CLAUDE_SKILL_DIR}/scripts/issue.sh list)\nBash(${CLAUDE_SKILL_DIR}/scripts/issue.sh list *)\nBash(${CLAUDE_SKILL_DIR}/scripts/issue.sh milestone list)'
  [map]='Bash(${CLAUDE_SKILL_DIR}/scripts/check-map.sh)'
)

case="Read-only script runs without a prompt"
for f in "${skills[@]}"; do
  s="$(basename "$(dirname "$f")")"
  want="$( { [ -z "${READONLY[$s]:-}" ] || echo "${READONLY[$s]}"; injected "$f" | sed 's/.*/Bash(&)/'; } | sort)"
  [ "$(allowed "$f" | sort)" = "$want" ] || fail "$s: allowed-tools is not exactly: ${want:-nothing}"
  while IFS= read -r e; do
    c="${e#Bash(}" c="${c%)}" c="${c% \*}"
    rg -qF -- "$c" <<<"$(body "$f")" || fail "$s: allowed $e is not a command in the body"
  done < <(allowed "$f")
done

case="State-changing script still asks"
# Any other way to write allowed-tools (one-line string, flow list, tab or column-0 items) would slip past the list above.
for f in "${skills[@]}"; do
  ! fm "$f" | rg -q '^allowed-tools:.*\S' || fail "$f: allowed-tools is not a block list"
  ! fm "$f" | rg -q '^(- |\t)' || fail "$f: frontmatter list item at column 0 or after a tab"
  ! fm "$f" | awk '/^allowed-tools:/ {f = 1; next} f && /^[^ ]/ {exit} f' | rg -v '^  - Bash\([^)]+\)$' || fail "$f: allowed-tools item is not '  - Bash(...)'"
done

case="Branch state shown at start"
for s in execute pr-ready; do
  rg -qxF '!`git status --short --branch || true`' "$P/skills/$s/SKILL.md" || fail "$s: branch state not injected"
done

case="Invoked outside a repository"
out="$(mktemp -d)"
for f in "${skills[@]}"; do
  while IFS= read -r c; do
    r="$(rg -o -r '$1' '^!`([^`]+)`$' "$f" | rg -F -m1 -- "$c")"
    # shellcheck disable=SC2086
    o="$(cd "$out" && unset GIT_DIR GIT_WORK_TREE && GIT_CEILING_DIRECTORIES="${out%/*}" bash -c "$r" 2>&1)" \
      || fail "$f: '$r' fails outside a repository, so the skill would not load"
    rg -q 'not a git repository' <<<"$o" || fail "$f: '$r' hides git's error outside a repository"
  done < <(injected "$f")
done
rm -rf "$out"

descs="$(rg -N '^description:' "${skills[@]}" "$P"/agents/*.md)"

case="Placeholder shown as written"
! rg '[<>]' <<<"$descs" || fail "a description holds < or >"

case="Description in third person"
! rg -i '\byour?\b' <<<"$descs" || fail "a description speaks to the reader"

case="Use case leads the description"
! rg ":description: [\"']?Gate " <<<"$descs" || fail "a description opens with its gate number"

ev="$P/evals"
# fires <skill>: the exact input_match line of a grader that matches that skill being invoked.
fires() { printf '%s%s"'"'" $'input_match: \'"skill"\\s*:\\s*"(?:[\\w-]+:)?' "$1"; }

case="Skill without a trigger case refused"
for d in "$P"/skills/*/; do
  s="$(basename "$d")" g="$ev/$(basename "$d")/graders/fires.md"
  [ -f "$ev/$s/prompt.md" ] && [ -f "$g" ] || fail "no trigger case for $s"
  # Byte for byte: any extra key (min, max, arm) could let the grader pass without the skill firing.
  [ "$(cat "$g")" = "$(printf -- '---\ntype: tool_used\ntool: Skill\n%s\n---' "$(fires "$s")")" ] || fail "$s: fires.md is not the Skill fired template"
done

case="Case outside the trigger limits refused"
for p in "$ev"/*/prompt.md; do
  h="$(fm "$p")"
  [ "$(rg -c '^allowed_tools:' <<<"$h")" = 1 ] && rg -qx 'allowed_tools: \[Skill\]' <<<"$h" || fail "$p: grants more than the Skill tool"
  [ "$(rg -c '^max_turns:' <<<"$h")" = 1 ] && rg -qx 'max_turns: [1-3]' <<<"$h" || fail "$p: max_turns not 1-3"
  t="$(rg -o -r '$1' '^timeout_seconds: ([0-9]+)$' <<<"$h" || true)"
  [ -n "$t" ] && [ "$t" -le 120 ] || fail "$p: timeout_seconds missing or over 120"
done

case="Boundary pair without a guard refused"
for pair in "slop refactor" "slop review" "refactor review" "investigate research" "investigate gap-analysis" \
  "research gap-analysis" "plan ship" "docs adr" "docs map" "adr map" "issues plan"; do
  read -r a b <<<"$pair"
  [ -f "$ev/$a/graders/not-$b.md" ] || [ -f "$ev/$b/graders/not-$a.md" ] || fail "no guard between $a and $b"
done

case="Chaining skill without a guard refused"
# A skill that chains into the expected one would fire it too, so its case must refuse the chaining skill.
for pair in "slop pr-ready" "slop execute" "review pr-ready" "review execute" "execute ship" "pr-ready ship"; do
  read -r a b <<<"$pair"
  [ -f "$ev/$a/graders/not-$b.md" ] || fail "$a case does not refuse $b, which chains into $a"
done

case="Neighbour grader that can pass on a call refused"
for g in "$ev"/*/graders/not-*.md; do
  s="${g##*/not-}" s="${s%.md}"
  [ -d "$P/skills/$s" ] || fail "$g: no skill named $s"
  for l in 'type: tool_used' 'tool: Skill' 'min: 0' 'max: 0' 'arm: both'; do rg -qxF "$l" "$g" || fail "$g: missing $l"; done
  rg -qxF -- "$(fires "$s")" "$g" || fail "$g: does not match skill $s"
done

case="Runner keeps write tools off"
# The one exec line, matched whole: a comment or a second command cannot stand in for it.
want='exec claude plugin eval "$root" --ablation none --no-publish --max-cost-usd "${SOLO_EVAL_MAX_USD:-5}" "$@" --disallow-tools Bash Write Edit NotebookEdit WebFetch WebSearch Agent'
[ "$(rg -c '^\s*exec ' "$ev/run.sh" || echo 0)" = 1 ] && rg -qxF -- "$want" "$ev/run.sh" || fail "evals/run.sh is not the one locked exec line"
! rg -n '^\s*[^#[:space:]]' "$ev/run.sh" | rg -v ':(set -euo pipefail|root=|exec claude plugin eval )' || fail "evals/run.sh runs more than the locked command"

case="Model-calling eval in hooks or CI refused"
# Everywhere a hook, workflow or plugin hook could live; docs and the suite itself may name the runner.
hits="$(rg -l --hidden -e 'plugin eval' -e 'run\.sh' -g '!.git/' -g '!evals/' -g '!openspec/' -g '!tests/' -g '!README.md' -g '!AGENTS.md' -g '!skills/**/*.md' -g '!skills/**/*.test.sh' "$P" || true)"
[ -z "$hits" ] || fail "may run the eval suite: $hits"

case="Commit guard wired on execute"
ef="$(fm "$P/skills/execute/SKILL.md")"
for l in 'hooks:' '  PreToolUse:' '    - matcher: "Bash"' '      hooks:' '        - type: command' "          command: 'bash \"\${CLAUDE_PLUGIN_ROOT}/skills/execute/scripts/commit-guard.sh\"'"; do
  rg -qxF -- "$l" <<<"$ef" || fail "execute frontmatter lacks: $l"
done
# once: would drop the guard after its first allowed run, possibly in another repository;
# an if: prefix rule would skip `git -C <dir> commit` and `env X=1 git commit`.
! rg -q 'once:|if:' <<<"$ef" || fail "commit guard is one-shot or filtered"
[ -f "$P/skills/execute/scripts/commit-guard.sh" ] || fail "commit-guard.sh missing"

echo "guards.test.sh: ok"
