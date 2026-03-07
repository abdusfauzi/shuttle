#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/tmp/ShuttleLocalInstallBuild}"
BUILD_CONFIGURATION="${BUILD_CONFIGURATION:-Release}"
DEST_APP="/Applications/Shuttle.app"
APP_BUILD_PATH="$DERIVED_DATA_PATH/Build/Products/$BUILD_CONFIGURATION/Shuttle.app"
ENTITLEMENTS_PATH="$ROOT_DIR/Shuttle/Shuttle.entitlements"

select_signing_identity() {
    local developer_id=""
    local apple_dev=""

    while read -r hash rest; do
        [[ -n "${hash:-}" ]] || continue
        case "$rest" in
        *"Developer ID Application:"*)
            if [[ -z "$developer_id" ]]; then
                developer_id="$hash"
            fi
            ;;
        *"Apple Development:"*)
            if [[ -z "$apple_dev" ]]; then
                apple_dev="$hash"
            fi
            ;;
        esac
    done < <(security find-identity -v -p codesigning 2>/dev/null | awk '/Apple Development:|Developer ID Application:/ {print $2, $0}')

    if [[ -n "$developer_id" ]]; then
        printf '%s\n' "$developer_id"
        return 0
    fi

    if [[ -n "$apple_dev" ]]; then
        printf '%s\n' "$apple_dev"
        return 0
    fi

    return 1
}

echo "== Shuttle local install =="
echo "Building $BUILD_CONFIGURATION bundle..."
xcodebuild \
    -project "$ROOT_DIR/Shuttle.xcodeproj" \
    -scheme Shuttle \
    -configuration "$BUILD_CONFIGURATION" \
    -sdk macosx \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    build

if [[ ! -d "$APP_BUILD_PATH" ]]; then
    echo "Build output missing: $APP_BUILD_PATH" >&2
    exit 1
fi

if signing_identity="$(select_signing_identity)"; then
    echo "Re-signing app bundle with local identity $signing_identity"
    codesign --force --deep --sign "$signing_identity" --entitlements "$ENTITLEMENTS_PATH" "$APP_BUILD_PATH"
else
    echo "No Apple Development or Developer ID identity found; keeping ad-hoc signature."
fi

echo "Installing to $DEST_APP"
pkill -x Shuttle >/dev/null 2>&1 || true
rm -rf "$DEST_APP"
ditto "$APP_BUILD_PATH" "$DEST_APP"
codesign --verify --verbose=2 "$DEST_APP"
open -a "$DEST_APP"

echo "Installed: $DEST_APP"
