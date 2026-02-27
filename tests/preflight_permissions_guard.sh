#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/Shuttle/OnboardingPreflight.swift"

[[ -f "$SOURCE_FILE" ]] || { echo "FAIL: missing OnboardingPreflight.swift" >&2; exit 1; }
grep -q "AXIsProcessTrusted" "$SOURCE_FILE" || { echo "FAIL: no Accessibility check" >&2; exit 1; }
grep -q "System Events" "$SOURCE_FILE" || { echo "FAIL: no AppleEvents probe" >&2; exit 1; }
grep -q "configReadable" "$SOURCE_FILE" || { echo "FAIL: no config readability check" >&2; exit 1; }

echo "OK: preflight service baseline present."
