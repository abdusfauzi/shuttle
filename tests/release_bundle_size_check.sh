#!/usr/bin/env bash
set -euo pipefail

APP_PATH="/tmp/ShuttleSignedBuild/Build/Products/Release/Shuttle.app"

[[ -d "$APP_PATH" ]] || { echo "FAIL: missing release app at $APP_PATH" >&2; exit 1; }

bundle_kb="$(du -sk "$APP_PATH" | awk '{print $1}')"

if [[ -d "$APP_PATH/Contents/Frameworks" ]]; then
    framework_count="$(ls -1 "$APP_PATH/Contents/Frameworks" | wc -l | tr -d ' ')"
else
    framework_count="0"
fi

if [[ "$framework_count" -ne 0 ]]; then
    echo "FAIL: expected 0 embedded Swift frameworks, found $framework_count" >&2
    exit 1
fi

if [[ "$bundle_kb" -gt 4096 ]]; then
    echo "FAIL: expected bundle <= 4096 KB, got ${bundle_kb} KB" >&2
    exit 1
fi

echo "OK: release bundle footprint check passed (${bundle_kb} KB, frameworks=$framework_count)."
