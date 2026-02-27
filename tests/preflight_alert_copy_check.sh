#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT_DIR/Shuttle/AppDelegate.swift"

grep -q "showPreflightOnboardingIfNeeded" "$SOURCE" || { echo "FAIL: onboarding entrypoint missing" >&2; exit 1; }
grep -q "Open Privacy Settings" "$SOURCE" || { echo "FAIL: missing privacy settings action" >&2; exit 1; }
grep -q "Open Config" "$SOURCE" || { echo "FAIL: missing open config action" >&2; exit 1; }

echo "OK: onboarding alert wiring present."
