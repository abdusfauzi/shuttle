#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK_SCRIPT="$ROOT_DIR/tests/terminal_parity_resource_check.sh"

apps=(
  "Terminal.app"
  "iTerm.app"
  "Warp.app"
  "Ghostty.app"
)

app_path() {
  case "$1" in
    "Terminal.app") echo "/System/Applications/Utilities/Terminal.app" ;;
    "iTerm.app") echo "/Applications/iTerm.app" ;;
    "Warp.app") echo "/Applications/Warp.app" ;;
    "Ghostty.app") echo "/Applications/Ghostty.app" ;;
    *) return 1 ;;
  esac
}

echo "== Terminal Parity Probe =="
echo "Date: $(date +%F)"
echo "macOS: $(sw_vers -productVersion)"
echo

echo "1) Preflight resource/routing check"
"$CHECK_SCRIPT"
echo

echo "2) Terminal app presence"
missing_count=0

for app in "${apps[@]}"; do
  path="$(app_path "$app")"

  if [[ -d "$path" ]]; then
    status="installed"
  else
    status="missing"
    missing_count=$((missing_count + 1))
  fi

  echo "- $app: $status | path=$path"
done
echo

if [[ "$missing_count" -gt 0 ]]; then
  echo "Result: BLOCKED ($missing_count required terminal app(s) missing)"
  exit 2
fi

echo "Result: READY_FOR_MANUAL_MATRIX"
