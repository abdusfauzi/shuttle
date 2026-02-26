#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$ROOT_DIR/Shuttle/apple-scpt"
DATE_UTC="$(date -u +%F)"

echo "== Terminal Parity Smoke =="
echo "Date (UTC): $DATE_UTC"
echo "Host macOS: $(sw_vers -productVersion)"
echo

echo "1) Preflight checks"
"$ROOT_DIR/tests/terminal_parity_resource_check.sh"
"$ROOT_DIR/tests/terminal_parity_probe.sh"
echo

echo "2) GUI automation capability checks"
set +e
osascript_terminal_err="$(osascript -e 'tell application "Terminal" to activate' 2>&1)"
osascript_terminal_rc=$?

open_terminal_err="$(/usr/bin/open -a /System/Applications/Utilities/Terminal.app 2>&1)"
open_terminal_rc=$?
set -e

echo "- osascript Terminal activate: rc=$osascript_terminal_rc"
if [[ -n "$osascript_terminal_err" ]]; then
  echo "  stderr: $osascript_terminal_err"
fi
echo "- open Terminal.app: rc=$open_terminal_rc"
if [[ -n "$open_terminal_err" ]]; then
  echo "  stderr: $open_terminal_err"
fi
echo

automation_blocked=0
if [[ "$osascript_terminal_rc" -ne 0 || "$open_terminal_rc" -ne 0 ]]; then
  automation_blocked=1
fi

echo "3) AppleScript handler invocation checks (syntax/dispatch only)"
run_script() {
  local label="$1"
  shift
  set +e
  local output
  output="$(osascript "$@" 2>&1)"
  local rc=$?
  set -e
  echo "- $label: rc=$rc"
  if [[ -n "$output" ]]; then
    echo "  stderr: $output"
  fi
}

run_script "terminal:new" "$SCRIPT_DIR/terminal-new-window.scpt" "echo shuttle-smoke" "basic" "Shuttle Smoke"
run_script "terminal:tab" "$SCRIPT_DIR/terminal-new-tab-default.scpt" "echo shuttle-smoke" "basic" "Shuttle Smoke"
run_script "terminal:current" "$SCRIPT_DIR/terminal-current-window.scpt" "echo shuttle-smoke"
run_script "virtual:screen" "$SCRIPT_DIR/virtual-with-screen.scpt" "echo shuttle-smoke" "Shuttle Smoke"
run_script "iterm-stable:new" "$SCRIPT_DIR/iTerm2-stable-new-window.scpt" "echo shuttle-smoke" "Default" "Shuttle Smoke"
run_script "iterm-stable:tab" "$SCRIPT_DIR/iTerm2-stable-new-tab-default.scpt" "echo shuttle-smoke" "Default" "Shuttle Smoke"
run_script "iterm-stable:current" "$SCRIPT_DIR/iTerm2-stable-current-window.scpt" "echo shuttle-smoke" "Default" "Shuttle Smoke"
run_script "iterm-nightly:new" "$SCRIPT_DIR/iTerm2-nightly-new-window.scpt" "echo shuttle-smoke" "Default" "Shuttle Smoke"
run_script "iterm-nightly:tab" "$SCRIPT_DIR/iTerm2-nightly-new-tab-default.scpt" "echo shuttle-smoke" "Default" "Shuttle Smoke"
run_script "iterm-nightly:current" "$SCRIPT_DIR/iTerm2-nightly-current-window.scpt" "echo shuttle-smoke" "Default" "Shuttle Smoke"
echo

if [[ "$automation_blocked" -eq 1 ]]; then
  echo "Result: BLOCKED_ENVIRONMENT"
  echo "Reason: GUI app launch and/or Apple Events are unavailable in this execution environment."
  exit 2
fi

echo "Result: MANUAL_MATRIX_REQUIRED"
