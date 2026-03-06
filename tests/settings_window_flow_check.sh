#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DELEGATE="$ROOT_DIR/Shuttle/AppDelegate.swift"
SETTINGS_CONTROLLER="$ROOT_DIR/Shuttle/SettingsWindowController.swift"

grep -q "private var settingsWindowController: SettingsWindowController\\?" "$APP_DELEGATE" || {
    echo "FAIL: settings window controller property missing" >&2
    exit 1
}

grep -q "@IBAction func showSettings" "$APP_DELEGATE" || {
    echo "FAIL: showSettings action missing" >&2
    exit 1
}

grep -q "showSettings(nil)" "$APP_DELEGATE" || {
    echo "FAIL: preflight should route to Settings" >&2
    exit 1
}

if grep -q "Open Privacy Settings" "$APP_DELEGATE"; then
    echo "FAIL: legacy blocking alert copy still present in AppDelegate" >&2
    exit 1
fi

grep -q "window?.center()" "$SETTINGS_CONTROLLER" || {
    echo "FAIL: Settings window is not centered on open" >&2
    exit 1
}

grep -q "NSTabView()" "$SETTINGS_CONTROLLER" || {
    echo "FAIL: Settings window should use a native tab view" >&2
    exit 1
}

grep -q 'identifier: "permissions"' "$SETTINGS_CONTROLLER" || {
    echo "FAIL: Permissions tab missing from Settings window" >&2
    exit 1
}

grep -q 'identifier: "config"' "$SETTINGS_CONTROLLER" || {
    echo "FAIL: Config tab missing from Settings window" >&2
    exit 1
}

grep -q 'identifier: "about"' "$SETTINGS_CONTROLLER" || {
    echo "FAIL: About tab missing from Settings window" >&2
    exit 1
}

grep -q "Last checked:" "$SETTINGS_CONTROLLER" || {
    echo "FAIL: Permissions tab does not expose refresh timestamp text" >&2
    exit 1
}

grep -q "Relaunch Shuttle" "$SETTINGS_CONTROLLER" || {
    echo "FAIL: Permissions tab does not provide a relaunch recovery action" >&2
    exit 1
}

grep -q "Not currently required for the selected terminal." "$SETTINGS_CONTROLLER" || {
    echo "FAIL: Permissions tab does not describe optional permission state" >&2
    exit 1
}

grep -q "Copy Local Default To" "$SETTINGS_CONTROLLER" || {
    echo "FAIL: local-to-destination copy action missing from Settings window" >&2
    exit 1
}

grep -q "Copy Active To Local Default" "$SETTINGS_CONTROLLER" || {
    echo "FAIL: active-to-local copy action missing from Settings window" >&2
    exit 1
}

echo "OK: settings window flow wiring present."
