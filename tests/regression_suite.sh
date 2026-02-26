#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WITH_COMPILE=0
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/tmp/ShuttleDerivedData}"

while (($#)); do
    case "$1" in
    --with-compile)
        WITH_COMPILE=1
        ;;
    *)
        echo "Unknown argument: $1" >&2
        echo "Usage: $0 [--with-compile]" >&2
        exit 1
        ;;
    esac
    shift
done

echo "== Shuttle Regression Suite =="
echo "Date (UTC): $(date -u +%F)"
echo "macOS: $(sw_vers -productVersion)"
echo

blocked=0

if [[ "$WITH_COMPILE" -eq 1 ]]; then
    echo "1) Recompile AppleScript resources"
    set +e
    "$ROOT_DIR/apple-scripts/compile-all.sh"
    compile_rc=$?
    set -e
    if [[ "$compile_rc" -eq 2 ]]; then
        blocked=1
    elif [[ "$compile_rc" -ne 0 ]]; then
        echo "Result: FAIL (compile step)" >&2
        exit "$compile_rc"
    fi
    echo
fi

echo "2) Terminal parity preflight"
"$ROOT_DIR/tests/terminal_parity_resource_check.sh"
"$ROOT_DIR/tests/terminal_parity_probe.sh"
echo

echo "3) Terminal parity smoke"
set +e
"$ROOT_DIR/tests/terminal_parity_smoke.sh"
smoke_rc=$?
set -e
if [[ "$smoke_rc" -eq 2 ]]; then
    blocked=1
elif [[ "$smoke_rc" -ne 0 ]]; then
    echo "Result: FAIL (smoke step)" >&2
    exit "$smoke_rc"
fi
echo

echo "4) Build validation"
xcodebuild \
    -project "$ROOT_DIR/Shuttle.xcodeproj" \
    -scheme Shuttle \
    -configuration Debug \
    -sdk macosx \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    build
echo

if [[ "$blocked" -eq 1 ]]; then
    echo "Result: REGRESSION_BLOCKED_ENVIRONMENT"
    echo "Reason: at least one step requires interactive macOS automation services."
    exit 2
fi

echo "Result: REGRESSION_PASS"
