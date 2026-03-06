#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/Shuttle/LaunchAtLoginController.swift"
fail=0

check_pattern() {
    local description="$1"
    local pattern="$2"
    if rg -q --fixed-strings -- "$pattern" "$SOURCE_FILE"; then
        echo "OK: $description"
    else
        echo "FAIL: $description" >&2
        fail=1
    fi
}

echo "== Launch-at-Login Isolation Check =="

check_pattern "Legacy login-item store helper exists" "private final class LegacyLoginItemStore" 
check_pattern "Controller depends on isolated legacy store" "private let legacyStore: LegacyLoginItemStore?" 
check_pattern "Legacy compatibility boundary is documented" "macOS 10.13-12.x compatibility boundary" 
check_pattern "Legacy helper owns raw LSSharedFileList handle" "private let loginItems: LSSharedFileList?"

if [[ "$fail" -ne 0 ]]; then
    echo "Result: FAIL"
    exit 1
fi

echo "Result: PASS"
