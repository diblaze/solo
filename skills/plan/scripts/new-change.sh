#!/usr/bin/env bash
# Usage: new-change.sh <slug>
# Initialises openspec/ when missing, creates the change, prints its path.
set -euo pipefail
slug="${1:?usage: new-change.sh <slug>}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$here/common.sh"
slug_ok "$slug"
[ -d openspec ] || "$here/openspec.sh" init --tools none >&2
[ -d "openspec/changes/$slug" ] || "$here/openspec.sh" new change "$slug" >&2
echo "openspec/changes/$slug"
