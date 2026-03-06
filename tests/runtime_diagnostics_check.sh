#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0

check_pattern() {
    local description="$1"
    local pattern="$2"
    local file="$3"
    if rg -q --fixed-strings -- "$pattern" "$file"; then
        echo "OK: $description"
    else
        echo "FAIL: $description" >&2
        fail=1
    fi
}

echo "== Runtime Diagnostics Check =="

check_pattern "Runtime diagnostics type exists" "enum RuntimeDiagnostics" "$ROOT_DIR/Shuttle/AppServices.swift"
check_pattern "Runtime diagnostics has environment toggle" "SHUTTLE_DIAGNOSTICS" "$ROOT_DIR/Shuttle/AppServices.swift"
check_pattern "Config snapshot load is measured" "RuntimeDiagnostics.measure(\"config.loadSnapshot\"" "$ROOT_DIR/Shuttle/AppServices.swift"
check_pattern "Menu build is measured" "RuntimeDiagnostics.measure(\"menu.build\"" "$ROOT_DIR/Shuttle/AppDelegate.swift"
check_pattern "Terminal dispatch is measured" "\"terminal.dispatch\"" "$ROOT_DIR/Shuttle/AppServices.swift"
check_pattern "Diagnostics emit structured NSLog entries" "Diagnostics[%@]" "$ROOT_DIR/Shuttle/AppServices.swift"

if [[ "$fail" -ne 0 ]]; then
    echo "Result: FAIL"
    exit 1
fi

echo "Result: PASS"
