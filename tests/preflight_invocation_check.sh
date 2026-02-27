#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT_DIR/Shuttle/AppDelegate.swift"

grep -q "showPreflightOnboardingIfNeeded()" "$SOURCE" || { echo "FAIL: preflight is never invoked" >&2; exit 1; }
grep -q "@IBAction func openHost" "$SOURCE" || { echo "FAIL: openHost action missing" >&2; exit 1; }

echo "OK: preflight invocation hooks present."
