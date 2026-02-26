#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_SERVICES="$ROOT_DIR/Shuttle/AppServices.swift"
SCRIPT_DIR="$ROOT_DIR/Shuttle/apple-scpt"

required_scripts=(
  "terminal-new-window.scpt"
  "terminal-current-window.scpt"
  "terminal-new-tab-default.scpt"
  "iTerm2-stable-new-window.scpt"
  "iTerm2-stable-current-window.scpt"
  "iTerm2-stable-new-tab-default.scpt"
  "iTerm2-nightly-new-window.scpt"
  "iTerm2-nightly-current-window.scpt"
  "iTerm2-nightly-new-tab-default.scpt"
  "virtual-with-screen.scpt"
)

echo "Checking AppleScript resources..."
for script_name in "${required_scripts[@]}"; do
  if [[ ! -f "$SCRIPT_DIR/$script_name" ]]; then
    echo "ERROR: missing script resource: Shuttle/apple-scpt/$script_name"
    exit 1
  fi
done

echo "Checking terminal and mode support markers in AppServices.swift..."
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
)

for marker in "${required_markers[@]}"; do
  if ! rg -q --fixed-strings "$marker" "$APP_SERVICES"; then
    echo "ERROR: missing marker in Shuttle/AppServices.swift: $marker"
    exit 1
  fi
done

echo "OK: parity resources and backend routing markers are present."
