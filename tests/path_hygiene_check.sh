#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Checking documentation/script path hygiene..."

if ! command -v rg >/dev/null 2>&1; then
    echo "ERROR: ripgrep (rg) is required for path hygiene checks." >&2
    exit 1
fi

patterns=(
    "/Users/abdusfauzi/Workspaces"
    "/User/abdusfauz/Workspaces"
    "~/Git/shuttle"
    "~/Workspaces/shuttle"
)

args=()
for pattern in "${patterns[@]}"; do
    args+=("-e" "$pattern")
done

set +e
matches="$(rg -n --glob '!tests/path_hygiene_check.sh' "${args[@]}" "$ROOT_DIR/README.md" "$ROOT_DIR/docs" "$ROOT_DIR/apple-scripts" "$ROOT_DIR/tests")"
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
    echo "FAIL: found hardcoded workstation paths:" >&2
    echo "$matches" >&2
    exit 1
fi

if [[ "$rc" -ne 1 ]]; then
    echo "ERROR: path hygiene scan failed with unexpected exit code: $rc" >&2
    exit "$rc"
fi

echo "OK: no hardcoded workstation paths detected."
