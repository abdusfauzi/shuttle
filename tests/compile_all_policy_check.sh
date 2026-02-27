#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

set +e
output="$("$ROOT_DIR/apple-scripts/compile-all.sh" 2>&1)"
rc=$?
set -e

if [[ "$rc" -ne 0 ]]; then
    echo "FAIL: compile-all.sh exited with $rc" >&2
    echo "$output" >&2
    exit 1
fi

if [[ "$output" != *"Skipping Warp legacy helper compilation"* ]]; then
    echo "FAIL: compile-all.sh did not report Warp legacy skip policy" >&2
    echo "$output" >&2
    exit 1
fi

echo "OK: compile-all.sh skips legacy Warp helpers by default."
