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

if [[ "$output" != *"Legacy Warp helper compilation is archived and not part of active build/test paths."* ]]; then
    echo "FAIL: compile-all.sh did not report Warp legacy archival policy" >&2
    echo "$output" >&2
    exit 1
fi

echo "OK: compile-all.sh excludes archived Warp legacy helpers from active build/test paths."
