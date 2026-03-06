#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DELEGATE="$ROOT_DIR/Shuttle/AppDelegate.swift"
SETTINGS_CONTROLLER="$ROOT_DIR/Shuttle/SettingsWindowController.swift"

grep -q "showPreflightOnboardingIfNeeded" "$APP_DELEGATE" || { echo "FAIL: onboarding entrypoint missing" >&2; exit 1; }
grep -q "showSettings(nil)" "$APP_DELEGATE" || { echo "FAIL: onboarding should route to Settings" >&2; exit 1; }
grep -q "Open Accessibility" "$SETTINGS_CONTROLLER" || { echo "FAIL: missing accessibility settings action" >&2; exit 1; }
grep -q "Choose Config File" "$SETTINGS_CONTROLLER" || { echo "FAIL: missing config selection action" >&2; exit 1; }

echo "OK: onboarding Settings window wiring present."
