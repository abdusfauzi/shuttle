#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMMON_LIB="$ROOT_DIR/apple-scripts/lib/compile-common.sh"

source "$COMMON_LIB"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

invalid_source="$tmp_dir/invalid.applescript"
output_scpt="$tmp_dir/invalid.scpt"

cat >"$invalid_source" <<'EOF'
on run
    this is not valid applescript
end run
EOF

set +e
compile_script "$output_scpt" "$invalid_source"
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
    echo "FAIL: compile_script returned success for invalid AppleScript" >&2
    exit 1
fi

echo "OK: compile_script propagates compiler failures (rc=$rc)."
