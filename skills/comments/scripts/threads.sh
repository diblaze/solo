#!/usr/bin/env bash
# One call per pull request review thread operation, so nobody composes gh api by hand.
# Input is checked before gh runs (exit 2); --dry-run prints each write instead of making it.
set -euo pipefail
usage() {
  cat >&2 <<'EOF'
usage: threads.sh <operation> [--dry-run]      --dry-run goes last
  list [<pr>] [--all]                     unresolved threads (--all: every thread) of the branch's PR
  reply <comment-id> --body-file <f> [--pr <n>]
                                          reply to the thread whose first comment is <comment-id>
  resolve <thread-id>...                  resolve PRRT_ threads, one call each
EOF
  exit 2
}
die() { echo "threads.sh: $*" >&2; exit 2; }
num() { [[ "$1" =~ ^[1-9][0-9]*$ ]] || die "not a positive number: $1"; }
# pr [<n>]: sets $owner, $repo and $n from the PR's URL, which names the base repository, also for a fork's PR.
pr() {
  local url
  url="$(gh pr view ${1:+"$1"} --json url --jq .url)"
  [[ "$url" =~ ^https://[^/]+/([^/]+)/([^/]+)/pull/([0-9]+)$ ]] || { echo "threads.sh: gh returned no pull request URL: $url" >&2; exit 1; }
  owner="${BASH_REMATCH[1]}" repo="${BASH_REMATCH[2]}" n="${BASH_REMATCH[3]}"
}

[ $# -gt 0 ] || usage
dry=""
if [ "${!#}" = --dry-run ]; then dry=1; set -- "${@:1:$#-1}"; fi
[ $# -gt 0 ] || usage
op="$1"; shift
# common.sh moves to the git root; a relative --body-file is the caller's.
start="$PWD"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../plan/scripts/common.sh"

case "$op" in
  list)
    all=false p=""
    for a in "$@"; do
      case "$a" in
        --all) all=true ;;
        -*) die "unknown option: $a" ;;
        *) [ -z "$p" ] || die "one pull request only"; p="${a#\#}"; num "$p" ;;
      esac
    done
    pr "$p"
    gh api graphql -f owner="$owner" -f repo="$repo" -F pr="$n" -f query='
      query($owner: String!, $repo: String!, $pr: Int!) {
        repository(owner: $owner, name: $repo) { pullRequest(number: $pr) { reviewThreads(first: 100) {
          pageInfo { hasNextPage }
          nodes { id isResolved isOutdated path line
            comments(first: 20) { pageInfo { hasNextPage } nodes { databaseId author { login } body } } }
        } } }
      }' --jq '.data.repository.pullRequest.reviewThreads
      | (if .pageInfo.hasNextPage then "# more than 100 threads; only the first 100 are shown" else empty end),
        "# total: \(.nodes | length) | unresolved: \([.nodes[] | select(.isResolved | not)] | length)",
        (.nodes[] | select('"$all"' or (.isResolved | not))
          | "THREAD \(.id) resolved=\(.isResolved) outdated=\(.isOutdated)",
            "path: \(.path) line: \(.line // "-") replyToId: \(.comments.nodes[0].databaseId // "-")",
            (.comments.nodes[] | "\(.author.login // "ghost"): \(.body)"),
            (if .comments.pageInfo.hasNextPage then "(more than 20 comments; later ones not shown)" else empty end),
            "----")'
    ;;
  reply)
    [ $# -gt 0 ] || usage
    cid="$1"; shift
    num "$cid"
    body="" p=""
    while [ $# -gt 0 ]; do
      [ $# -ge 2 ] && [ -n "$2" ] || die "$1 needs a value"
      case "$1" in
        --body-file) f="$2"; [[ "$f" = /* ]] || f="$start/$f"; [ -f "$f" ] || die "no such file: $2"; body="$f" ;;
        --pr) p="${2#\#}"; num "$p" ;;
        *) die "unknown option: $1" ;;
      esac
      shift 2
    done
    [ -n "$body" ] || die "reply needs --body-file"
    pr "$p"
    write gh api "repos/$owner/$repo/pulls/$n/comments/$cid/replies" -F "body=@$body" --silent
    # The user approves the text, not the path.
    [ -z "$dry" ] || cat -- "$body"
    ;;
  resolve)
    [ $# -gt 0 ] || usage
    for t in "$@"; do [[ "$t" =~ ^PRRT_[A-Za-z0-9_-]+$ ]] || die "not a review thread id: $t"; done
    for t in "$@"; do
      write gh api graphql -f threadId="$t" -f query='
        mutation($threadId: ID!) { resolveReviewThread(input: {threadId: $threadId}) { thread { id } } }'
      [ -n "$dry" ] || echo "$t resolved"
    done
    ;;
  *) usage ;;
esac
