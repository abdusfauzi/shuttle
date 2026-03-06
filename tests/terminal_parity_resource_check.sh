#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_SERVICES="$ROOT_DIR/Shuttle/AppServices.swift"

echo "Checking embedded terminal script catalog and routing markers in AppServices.swift..."
required_markers=(
  "case terminal"
  "case iterm"
  "case warp"
  "case ghostty"
  "case new"
  "case current"
  "case tab"
  "case virtual"
  "struct TerminalAppBackend"
  "struct ITermBackend"
  "struct WarpBackend"
  "struct GhosttyBackend"
  "static let terminalNewWindow"
  "static let terminalCurrentWindow"
  "static let terminalNewTabDefault"
  "static let iTermNewWindow"
  "static let iTermCurrentWindow"
  "static let iTermNewTabDefault"
  "static let virtualWithScreen"
  "runScript(scriptSource"
  "cachedScript(source:"
)

for marker in "${required_markers[@]}"; do
  if ! rg -q --fixed-strings "$marker" "$APP_SERVICES"; then
    echo "ERROR: missing marker in Shuttle/AppServices.swift: $marker"
    exit 1
  fi
done

echo "OK: parity resources and backend routing markers are present."
