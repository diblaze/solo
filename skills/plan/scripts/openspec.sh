#!/usr/bin/env bash
# Runs the pinned OpenSpec CLI: the global binary only at that exact version, else npx.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$here/common.sh"
v=1.14.1
if command -v openspec >/dev/null 2>&1; then
  g="$(openspec --version 2>/dev/null || true)"
  [ "$g" != "$v" ] || exec openspec "$@"
  echo "openspec.sh: global openspec $g != $v, using npx" >&2
fi
command -v npx >/dev/null 2>&1 || { echo "openspec.sh: neither openspec $v nor npx on PATH" >&2; exit 127; }
exec npx -y "@fission-ai/openspec@$v" "$@"
