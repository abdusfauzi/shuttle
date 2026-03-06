#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_SERVICES="$ROOT_DIR/Shuttle/AppServices.swift"
DATE_UTC="$(date -u +%F)"
APPLE_SCRIPT_TIMEOUT_SECONDS="${TERMINAL_PARITY_APPLESCRIPT_TIMEOUT_SECONDS:-8}"
INTERACTIVE_SMOKE="${TERMINAL_PARITY_INTERACTIVE_SMOKE:-0}"
TERMINAL_SMOKE_WINDOW_TITLE="Shuttle Smoke $(date -u +%H%M%S)-$$"

cleanup_terminal_smoke_artifacts() {
  local cleanup_script

  if [[ -z "${TERMINAL_SMOKE_WINDOW_TITLE:-}" ]] || ! command -v osascript >/dev/null 2>&1; then
    return 0
  fi

  cleanup_script="$(mktemp)"
  {
cat <<EOF
on run argv
  set marker to item 1 of argv

  tell application "Terminal"
    if it is running then
      repeat with wi from (count windows) to 1 by -1
        set targetWindow to window wi
        repeat with ti from (count tabs of targetWindow) to 1 by -1
          try
            if (custom title of tab ti of targetWindow) is marker then
              close tab ti of targetWindow
            end if
          end try
        end repeat
        try
          if (count tabs of targetWindow) is 0 then
            close targetWindow
          end if
        end try
      end repeat
    end if
  end tell

  tell application "iTerm"
    if it is running then
      repeat with wi from (count windows) to 1 by -1
        set targetWindow to window wi
        repeat with si from (count sessions of targetWindow) to 1 by -1
          try
            if (name of session si of targetWindow) is marker then
              close session si of targetWindow
            end if
          end try
        end repeat
        try
          if (count sessions of targetWindow) is 0 then
            close targetWindow
          end if
        end try
      end repeat
    end if
  end tell
end run
EOF
} > "$cleanup_script"

  set +e
  osascript "$cleanup_script" "$TERMINAL_SMOKE_WINDOW_TITLE" >/dev/null 2>&1 || true
  rm -f "$cleanup_script"
  set -e
}

trap cleanup_terminal_smoke_artifacts EXIT

extract_script_source() {
  local symbol="$1"
  awk -v marker="static let ${symbol} = \"\"\"" '
    $0 ~ marker { capture = 1; next }
    capture && $0 ~ /^"""/ { exit }
    capture { print }
  ' "$APP_SERVICES"
}

run_osascript_with_timeout() {
  local tmp_script="$1"
  shift

  set +e
  if command -v python3 >/dev/null 2>&1; then
    local raw_output
    raw_output="$(python3 - "$tmp_script" "$APPLE_SCRIPT_TIMEOUT_SECONDS" "$@" <<'PY'
import subprocess
import sys

script_path = sys.argv[1]
timeout = float(sys.argv[2])
args = sys.argv[3:]

try:
    proc = subprocess.run(
        ["osascript", script_path, *args],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
        timeout=timeout,
    )
except subprocess.TimeoutExpired:
    print(f"timeout after {timeout:.0f}s")
    raise SystemExit(124)

if proc.stdout:
    print(proc.stdout.rstrip("\n"), end="")
raise SystemExit(proc.returncode)
PY
)"
    local rc=$?
  else
    raw_output="$(osascript "$tmp_script" "$@" 2>&1)"
    local rc=$?
  fi
  set -e

  printf '%s' "$raw_output"
  return $rc
}

run_template_script() {
  local label="$1"
  local symbol="$2"
  shift 2

  local template
  template="$(extract_script_source "$symbol")"
  if [[ -z "$template" ]]; then
    echo "- $label: ERROR: missing template '$symbol' in AppServices.swift"
    return 1
  fi

  if ! command -v osascript >/dev/null 2>&1; then
    echo "- $label: rc=127"
    echo "  stderr: osascript is unavailable in this environment"
    return 127
  fi

  local tmp_script
  tmp_script="$(mktemp)"
  {
  printf '%s\n' "$template"
  cat <<'EOF'
on run argv
  if (count of argv) is 3 then
    scriptRun(item 1 of argv, item 2 of argv, item 3 of argv)
  else if (count of argv) is 2 then
    scriptRun(item 1 of argv, item 2 of argv)
  else
    scriptRun(item 1 of argv)
    end if
end run
EOF
  } > "$tmp_script"

  set +e
  local output
  output="$(run_osascript_with_timeout "$tmp_script" "$@" 2>&1)"
  local rc=$?
  set -e
  rm -f "$tmp_script"

  echo "- $label: rc=$rc"
  if [[ -n "$output" ]]; then
    echo "  stderr: $output"
  fi
}

compile_applescript_file() {
  local label="$1"
  local file_path="$2"

  if ! command -v osacompile >/dev/null 2>&1; then
    echo "- $label: rc=127"
    echo "  stderr: osacompile is unavailable in this environment"
    return 127
  fi

  local compiled_output
  compiled_output="$(mktemp "${TMPDIR:-/tmp}/shuttle-smoke-XXXXXX.scpt")"
  rm -f "$compiled_output"

  set +e
  local output
  output="$(osacompile -o "$compiled_output" "$file_path" 2>&1)"
  local rc=$?
  set -e

  rm -f "$compiled_output"

  echo "- $label: rc=$rc"
  if [[ -n "$output" ]]; then
    echo "  stderr: $output"
  fi
  return $rc
}

compile_template_script() {
  local label="$1"
  local symbol="$2"

  local template
  template="$(extract_script_source "$symbol")"
  if [[ -z "$template" ]]; then
    echo "- $label: ERROR: missing template '$symbol' in AppServices.swift"
    return 1
  fi

  local tmp_script
  tmp_script="$(mktemp)"
  {
    printf '%s\n' "$template"
    cat <<'EOF'
on run argv
  return "compiled"
end run
EOF
  } > "$tmp_script"

  compile_applescript_file "$label" "$tmp_script"
  local rc=$?
  rm -f "$tmp_script"
  return $rc
}

compile_ui_controlled_script() {
  local label="$1"
  local tmp_script

  tmp_script="$(mktemp)"
  cat > "$tmp_script" <<'EOF'
on run argv
    set terminalName to item 1 of argv
    set terminalCommand to item 2 of argv
    set terminalWindow to item 3 of argv

    set wasRunning to application terminalName is running
    tell application terminalName to activate
    delay 0.2

    tell application "System Events"
        tell process terminalName
            if terminalWindow is "new" then
                keystroke "n" using {command down}
                delay 0.1
            else if terminalWindow is "tab" then
                if wasRunning then
                    keystroke "t" using {command down}
                    delay 0.1
                end if
            end if

            keystroke terminalCommand
            key code 36
        end tell
    end tell
end run
EOF

  compile_applescript_file "$label" "$tmp_script"
  local rc=$?
  rm -f "$tmp_script"
  return $rc
}

echo "== Terminal Parity Smoke =="
echo "Date (UTC): $DATE_UTC"
echo "Host macOS: $(sw_vers -productVersion)"
echo "Interactive mode: $INTERACTIVE_SMOKE"
echo

echo "1) Preflight checks"
"$ROOT_DIR/tests/terminal_parity_resource_check.sh"
"$ROOT_DIR/tests/terminal_parity_probe.sh"
echo

automation_blocked=0
invocation_blocked=0

if [[ "$INTERACTIVE_SMOKE" == "1" ]]; then
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

  if [[ "$osascript_terminal_rc" -ne 0 || "$open_terminal_rc" -ne 0 ]]; then
    automation_blocked=1
  fi

  echo "3) AppleScript handler invocation checks (interactive)"
  set +e
  run_template_script "terminal:new" "terminalNewWindow" "echo shuttle-smoke" "basic" "$TERMINAL_SMOKE_WINDOW_TITLE" || invocation_blocked=$((invocation_blocked + 1))
  run_template_script "terminal:tab" "terminalNewTabDefault" "echo shuttle-smoke" "basic" "$TERMINAL_SMOKE_WINDOW_TITLE" || invocation_blocked=$((invocation_blocked + 1))
  run_template_script "terminal:current" "terminalCurrentWindow" "echo shuttle-smoke" || invocation_blocked=$((invocation_blocked + 1))
  run_template_script "virtual:screen" "virtualWithScreen" "echo shuttle-smoke" "Shuttle Smoke" || invocation_blocked=$((invocation_blocked + 1))
  run_template_script "iterm-stable:new" "iTermNewWindow" "echo shuttle-smoke" "Default" "$TERMINAL_SMOKE_WINDOW_TITLE" || invocation_blocked=$((invocation_blocked + 1))
  run_template_script "iterm-stable:tab" "iTermNewTabDefault" "echo shuttle-smoke" "Default" "$TERMINAL_SMOKE_WINDOW_TITLE" || invocation_blocked=$((invocation_blocked + 1))
  run_template_script "iterm-stable:current" "iTermCurrentWindow" "echo shuttle-smoke" || invocation_blocked=$((invocation_blocked + 1))
  run_template_script "iterm-nightly:new" "iTermNewWindow" "echo shuttle-smoke" "Default" "$TERMINAL_SMOKE_WINDOW_TITLE" || invocation_blocked=$((invocation_blocked + 1))
  run_template_script "iterm-nightly:tab" "iTermNewTabDefault" "echo shuttle-smoke" "Default" "$TERMINAL_SMOKE_WINDOW_TITLE" || invocation_blocked=$((invocation_blocked + 1))
  run_template_script "iterm-nightly:current" "iTermCurrentWindow" "echo shuttle-smoke" || invocation_blocked=$((invocation_blocked + 1))
  set -e
  echo

  if [[ "$automation_blocked" -eq 1 ]]; then
    echo "Result: BLOCKED_ENVIRONMENT"
    echo "Reason: GUI app launch and/or Apple Events are unavailable in this execution environment."
    exit 2
  fi

  if [[ "$invocation_blocked" -ne 0 ]]; then
    echo "Result: BLOCKED_ENVIRONMENT"
    echo "Reason: script template execution is unavailable or timed out in this environment."
    exit 2
  fi

  echo "Result: MANUAL_MATRIX_REQUIRED"
else
  echo "2) Non-invasive AppleScript compile checks"
  set +e
  compile_template_script "terminal:new" "terminalNewWindow" || invocation_blocked=$((invocation_blocked + 1))
  compile_template_script "terminal:tab" "terminalNewTabDefault" || invocation_blocked=$((invocation_blocked + 1))
  compile_template_script "terminal:current" "terminalCurrentWindow" || invocation_blocked=$((invocation_blocked + 1))
  compile_template_script "virtual:screen" "virtualWithScreen" || invocation_blocked=$((invocation_blocked + 1))
  compile_template_script "iterm-stable:new" "iTermNewWindow" || invocation_blocked=$((invocation_blocked + 1))
  compile_template_script "iterm-stable:tab" "iTermNewTabDefault" || invocation_blocked=$((invocation_blocked + 1))
  compile_template_script "iterm-stable:current" "iTermCurrentWindow" || invocation_blocked=$((invocation_blocked + 1))
  compile_template_script "iterm-nightly:new" "iTermNewWindow" || invocation_blocked=$((invocation_blocked + 1))
  compile_template_script "iterm-nightly:tab" "iTermNewTabDefault" || invocation_blocked=$((invocation_blocked + 1))
  compile_template_script "iterm-nightly:current" "iTermCurrentWindow" || invocation_blocked=$((invocation_blocked + 1))
  compile_ui_controlled_script "ui-controlled:warp/ghostty" || invocation_blocked=$((invocation_blocked + 1))
  set -e
  echo

  if [[ "$invocation_blocked" -ne 0 ]]; then
    echo "Result: FAIL"
    echo "Reason: one or more AppleScript smoke templates failed to compile."
    exit 1
  fi

  echo "Result: SAFE_PASS"
fi
