#!/bin/bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_FILE="$ROOT_DIR/scripts/install_local_app.sh"
[ -f "$SCRIPT_FILE" ] || { echo 'FAIL: missing local install script' >&2; exit 1; }
grep -q 'security find-identity' "$SCRIPT_FILE" || { echo 'FAIL: install script does not inspect signing identities' >&2; exit 1; }
grep -q 'Developer ID Application:' "$SCRIPT_FILE" || { echo 'FAIL: install script does not prefer Developer ID signing when available' >&2; exit 1; }
grep -q 'codesign --force --deep --sign' "$SCRIPT_FILE" || { echo 'FAIL: install script does not perform bundle re-signing' >&2; exit 1; }
grep -q '/Applications/Shuttle.app' "$SCRIPT_FILE" || { echo 'FAIL: install script does not target /Applications/Shuttle.app' >&2; exit 1; }
echo 'PASS: local install signing script present'
