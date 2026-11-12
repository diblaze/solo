#!/usr/bin/env bash
# Usage: bash evals/run.sh [--case <glob>] [--runs <n>] [--model <m>] [other `claude plugin eval` flags]
# Runs the skill trigger suite. It spends model usage: about cases x runs agent runs (16 x 3 = 48 by default).
# One arm, because a "skill fired" grader can never pass without the plugin. The report stays local, and
# SOLO_EVAL_MAX_USD (default 5) caps the list-price estimate. Shell, file-write, web and subagent tools
# are withheld after any flag passed here, so no case can push, open a PR or touch an issue.
# Never called by lefthook or CI (tests/guards.test.sh checks that).
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec claude plugin eval "$root" --ablation none --no-publish --max-cost-usd "${SOLO_EVAL_MAX_USD:-5}" "$@" --disallow-tools Bash Write Edit NotebookEdit WebFetch WebSearch Agent
