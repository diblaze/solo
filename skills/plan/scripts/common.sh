# Sourced by every change script: needs rg, works from the git root, validates input.
command -v rg >/dev/null 2>&1 || { echo "${0##*/}: ripgrep (rg) is required" >&2; exit 127; }
# An inherited GIT_DIR (git rebase --exec in a worktree) makes --show-toplevel return the cwd.
[ -n "${GIT_WORK_TREE:-}" ] || unset GIT_DIR
root="$(git rev-parse --show-toplevel)"
cd "$root"
ISSUE_RE='[A-Za-z0-9._-]+/[A-Za-z0-9._-]+#[0-9]+'
# issue_of <proposal>: the owner/repo#n it names, nothing for none; refuses unless exactly one valid Issue: line.
issue_of() {
  [ "$(rg -c '^Issue:' "$1" || echo 0)" -eq 1 ] && rg -q "^Issue: ($ISSUE_RE|none)\s*$" "$1" \
    || { echo "${0##*/}: $1 needs exactly one 'Issue: owner/repo#n' or 'Issue: none' line" >&2; exit 1; }
  rg -o -r '$1' "^Issue: ($ISSUE_RE)\s*$" "$1" || true
}
slug_ok() { [[ "$1" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || { echo "${0##*/}: slug must be kebab-case: $1" >&2; exit 2; }; }
