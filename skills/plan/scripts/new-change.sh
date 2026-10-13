#!/usr/bin/env bash
# Usage: new-change.sh <slug>   (run at repo root)
# Initialises openspec/ when missing, creates the change, prints its path.
set -euo pipefail
slug="${1:?usage: new-change.sh <slug>}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ "$slug" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || { echo "new-change.sh: slug must be kebab-case: $slug" >&2; exit 2; }
[ -d openspec ] || "$here/openspec.sh" init --tools none >&2
[ -d "openspec/changes/$slug" ] || "$here/openspec.sh" new change "$slug" >&2
echo "openspec/changes/$slug"
