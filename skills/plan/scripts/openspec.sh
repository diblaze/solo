#!/usr/bin/env bash
# Runs the OpenSpec CLI: global binary when installed, else npx pinned to major 1.
set -euo pipefail
if command -v openspec >/dev/null 2>&1; then
  exec openspec "$@"
fi
command -v npx >/dev/null 2>&1 || { echo "openspec.sh: neither openspec nor npx on PATH" >&2; exit 127; }
exec npx -y @fission-ai/openspec@1 "$@"
