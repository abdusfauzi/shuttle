#!/usr/bin/env bash
set -euo pipefail

APP_PATH="/tmp/ShuttleSignedBuild/Build/Products/Release/Shuttle.app"
MAX_BUNDLE_KB=6144
MAX_SWIFT_DYLIBS=20

[[ -d "$APP_PATH" ]] || { echo "FAIL: missing release app at $APP_PATH" >&2; exit 1; }

bundle_kb="$(du -sk "$APP_PATH" | awk '{print $1}')"

if [[ -d "$APP_PATH/Contents/Frameworks" ]]; then
    framework_count="$(find "$APP_PATH/Contents/Frameworks" -maxdepth 1 -type f | wc -l | tr -d ' ')"
else
    framework_count="0"
fi

unexpected_frameworks="$(
    find "$APP_PATH/Contents/Frameworks" -maxdepth 1 -type f 2>/dev/null \
        | xargs -I{} basename "{}" \
        | rg -v '^libswift.*\.dylib$' || true
)"

if [[ -n "$unexpected_frameworks" ]]; then
    echo "FAIL: unexpected non-Swift runtime frameworks in release bundle:" >&2
    echo "$unexpected_frameworks" >&2
    exit 1
fi

if [[ "$framework_count" -gt "$MAX_SWIFT_DYLIBS" ]]; then
    echo "FAIL: expected <= ${MAX_SWIFT_DYLIBS} embedded Swift dylibs for macOS 10.13 compatibility, found $framework_count" >&2
    exit 1
fi

if [[ "$bundle_kb" -gt "$MAX_BUNDLE_KB" ]]; then
    echo "FAIL: expected bundle <= ${MAX_BUNDLE_KB} KB, got ${bundle_kb} KB" >&2
    exit 1
fi

echo "OK: release bundle footprint check passed (${bundle_kb} KB, frameworks=$framework_count)."
