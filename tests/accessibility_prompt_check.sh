#!/bin/bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/Shuttle/AppDelegate.swift"
grep -q 'AXIsProcessTrustedWithOptions' "$SOURCE_FILE" || { echo 'FAIL: missing Accessibility trust prompt flow' >&2; exit 1; }
grep -q 'kAXTrustedCheckOptionPrompt' "$SOURCE_FILE" || { echo 'FAIL: missing Accessibility prompt option' >&2; exit 1; }
echo 'PASS: Accessibility prompt flow present'
