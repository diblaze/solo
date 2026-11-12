#!/usr/bin/env bash
# One call per GitHub issue operation, so nobody composes gh by hand. usage() below lists them.
# Input is checked before gh runs (exit 2); --dry-run prints each write instead of making it.
# feat, bug and chore are GitHub's issue types Feature, Bug and Task, not labels.
set -euo pipefail
usage() {
  cat >&2 <<'EOF'
usage: issue.sh <operation> [--dry-run]      --dry-run goes last
  create --title <t> --body-file <f> --type feat|bug|chore
         [--milestone <title>] [--assignee <login>] [--blocked-by <n>]...   prints owner/repo#n
  edit <n> [--title <t>] [--body-file <f>] [--type feat|bug|chore]
         [--milestone <title> | --remove-milestone]
         [--add-assignee <login>] [--remove-assignee <login>]
         [--add-blocked-by <n>] [--remove-blocked-by <n>]
  comment <n> --body-file <f>
  close <n> [--reason completed|not-planned | --duplicate-of <n>]
  reopen <n>
EOF
  exit 2
}
die() { echo "issue.sh: $*" >&2; exit 2; }
num() { n="${1#\#}"; [[ "$n" =~ ^[1-9][0-9]*$ ]] || die "not an issue number: $1"; }
# kind <feat|bug|chore>: sets $t to GitHub's issue type of that name.
kind() {
  case "$1" in feat) t=Feature ;; bug) t=Bug ;; chore) t=Task ;; *) die "type must be feat, bug or chore: $1" ;; esac
}
login() { [[ "$1" =~ ^(@me|[A-Za-z0-9](-?[A-Za-z0-9])*)$ ]] || die "not a login: $1"; }
file() { f="$1"; [[ "$f" = /* ]] || f="$start/$f"; [ -f "$f" ] || die "no such file: $1"; }
# val <option> [value…]: the option has a non-empty value after it.
val() { [ $# -ge 2 ] && [ -n "$2" ] || die "$1 needs a value"; }

[ $# -gt 0 ] || usage
# Last only: anywhere else it is a value (a title may read --dry-run) or an unknown option.
dry=""
if [ "${!#}" = --dry-run ]; then dry=1; set -- "${@:1:$#-1}"; fi
[ $# -gt 0 ] || usage
op="$1"; shift
# common.sh moves to the git root; a relative --body-file is the caller's.
start="$PWD"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../plan/scripts/common.sh"

case "$op" in
  create)
    title="" body="" k="" who="@me" more=()
    while [ $# -gt 0 ]; do
      val "$@"
      case "$1" in
        --title) title="$2" ;;
        --body-file) file "$2"; body="$f" ;;
        --type) kind "$2"; k="$t" ;;
        --milestone) more+=(--milestone "$2") ;;
        --assignee) login "$2"; who="$2" ;;
        --blocked-by) num "$2"; more+=(--blocked-by "$n") ;;
        *) die "unknown option: $1" ;;
      esac
      shift 2
    done
    [ -n "$title" ] && [ -n "$body" ] && [ -n "$k" ] || die "create needs --title, --body-file and --type"
    args=(gh issue create --title "$title" --body-file "$body" --type "$k" --assignee "$who" ${more[@]+"${more[@]}"})
    if [ -n "$dry" ]; then
      write "${args[@]}"
    else
      url="$("${args[@]}")"
      [[ "$url" =~ ^https://[^/]+/([^/]+/[^/]+)/issues/([0-9]+)$ ]] || { echo "issue.sh: gh did not return an issue URL: $url" >&2; exit 1; }
      echo "${BASH_REMATCH[1]}#${BASH_REMATCH[2]}"
    fi
    ;;
  edit)
    num "${1:-}"; shift
    i="$n" ms=0 e=()
    while [ $# -gt 0 ]; do
      if [ "$1" = --remove-milestone ]; then e+=("$1"); ms=$((ms + 1)); shift; continue; fi
      val "$@"
      case "$1" in
        --title) e+=("$1" "$2") ;;
        --milestone) e+=("$1" "$2"); ms=$((ms + 1)) ;;
        --body-file) file "$2"; e+=("$1" "$f") ;;
        --type) kind "$2"; e+=("$1" "$t") ;;
        --add-assignee | --remove-assignee) login "$2"; e+=("$1" "$2") ;;
        --add-blocked-by | --remove-blocked-by) num "$2"; e+=("$1" "$n") ;;
        *) die "unknown option: $1" ;;
      esac
      shift 2
    done
    [ ${#e[@]} -gt 0 ] || die "edit needs a change"
    [ "$ms" -le 1 ] || die "edit takes one of --milestone and --remove-milestone"
    write gh issue edit "$i" "${e[@]}"
    ;;
  comment)
    num "${1:-}"
    [ $# -eq 3 ] && [ "$2" = --body-file ] || die "comment needs <n> --body-file <f>"
    file "$3"
    write gh issue comment "$n" --body-file "$f"
    ;;
  close)
    num "${1:-}"; shift
    i="$n" how=(--reason completed)
    bad="close takes --reason completed|not-planned or --duplicate-of <n>"
    if [ $# -eq 2 ]; then
      case "$1" in
        --reason) case "$2" in completed) ;; not-planned) how=(--reason "not planned") ;; *) die "$bad" ;; esac ;;
        --duplicate-of) num "$2"; how=(--duplicate-of "$n") ;;
        *) die "$bad" ;;
      esac
    elif [ $# -ne 0 ]; then
      die "$bad"
    fi
    write gh issue close "$i" "${how[@]}"
    ;;
  reopen)
    num "${1:-}"
    [ $# -eq 1 ] || die "reopen takes <n>"
    write gh issue reopen "$n"
    ;;
  *) usage ;;
esac
