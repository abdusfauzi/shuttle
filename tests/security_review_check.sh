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

forbidden_pattern() {
    local description="$1"
    local pattern="$2"
    local file="$3"
    if rg -q --fixed-strings -- "$pattern" "$file"; then
        echo "FAIL: $description" >&2
        fail=1
    else
        echo "OK: $description"
    fi
}

echo "== Security Review Check =="

check_pattern "SecurityPolicies defines max command length policy" "static let maxCommandLength" "$ROOT_DIR/Shuttle/AppServices.swift"
check_pattern "SecurityPolicies has allowed open mode sanitizer" "static func sanitizeOpenMode(_ candidate" "$ROOT_DIR/Shuttle/AppServices.swift"
check_pattern "SecurityPolicies can validate host alias" "static func isSafeHostAlias(_ alias" "$ROOT_DIR/Shuttle/AppServices.swift"
check_pattern "SSH host commands use shell-safe quoting" "return \"ssh \\(SecurityPolicies.shellSingleQuote(trimmedKey))\"" "$ROOT_DIR/Shuttle/AppServices.swift"
forbidden_pattern "No unquoted SSH host command interpolation" "itemList.add([\"name\": leaf, \"cmd\": \"ssh \\(key)\"])" "$ROOT_DIR/Shuttle/AppServices.swift"
check_pattern "Open-mode resolution normalizes commandWindow and checks allow-list" "allowedOpenModes.contains(normalizedCommandWindow)" "$ROOT_DIR/Shuttle/AppServices.swift"
check_pattern "Open-mode resolution rejects invalid inTerminal values" "bad \\\"inTerminal\\\":\\\"VALUE\\\" in the JSON settings" "$ROOT_DIR/Shuttle/AppServices.swift"
check_pattern "Editor command path is shell-quoted" "SecurityPolicies.shellSingleQuote(shuttleConfigFile)" "$ROOT_DIR/Shuttle/AppDelegate.swift"
check_pattern "Missing terminal scripts fail fast and surface error" "Unable to run Terminal.app script" "$ROOT_DIR/Shuttle/AppServices.swift"
check_pattern "Ghostty direct launch validates command safety" "runGhosttyDirect" "$ROOT_DIR/Shuttle/AppServices.swift"
check_pattern "runGhosttyDirect blocks unsafe commands" "isSafeCommand(command)" "$ROOT_DIR/Shuttle/AppServices.swift"
check_pattern "About window fallback open command uses background open argument" "task.arguments = [\"-g\", url.absoluteString]" "$ROOT_DIR/Shuttle/AboutWindowController.swift"
check_pattern "runScript now returns explicit success/failure" "private func runScript(scriptPath" "$ROOT_DIR/Shuttle/AppServices.swift"

if [[ "$fail" -ne 0 ]]; then
    echo "Result: FAIL"
    exit 1
fi

echo "Result: PASS"
