#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_SERVICES="$ROOT_DIR/Shuttle/AppServices.swift"
DATE_UTC="$(date -u +%F_%H-%M-%SZ)"
REPORT_FILE="$ROOT_DIR/tests/terminal-parity-matrix-capture-${DATE_UTC}.md"
APPLE_SCRIPT_TIMEOUT_SECONDS="${TERMINAL_PARITY_APPLESCRIPT_TIMEOUT_SECONDS:-8}"
INTERACTIVE_MATRIX="${TERMINAL_PARITY_INTERACTIVE_MATRIX:-0}"
MATRIX_SMOKE_WINDOW_TITLE="Shuttle Matrix $(date -u +%H%M%S)-$$"

cleanup_matrix_terminal_artifacts() {
  local cleanup_script

  if [[ -z "${MATRIX_SMOKE_WINDOW_TITLE:-}" ]] || ! command -v osascript >/dev/null 2>&1; then
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
  osascript "$cleanup_script" "$MATRIX_SMOKE_WINDOW_TITLE" >/dev/null 2>&1 || true
  rm -f "$cleanup_script"
  set -e
}

trap cleanup_matrix_terminal_artifacts EXIT

if [[ ! -x "$ROOT_DIR/tests/terminal_parity_resource_check.sh" || ! -x "$ROOT_DIR/tests/terminal_parity_probe.sh" ]]; then
    echo "FAIL: required parity scripts are not executable" >&2
    exit 1
fi

append_row() {
    local row="$1"
    echo "$row" | tee -a "$REPORT_FILE"
}

total_cells=0
passed_cells=0
failed_cells=0

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

compile_applescript_file() {
    local terminal_label="$1"
    local open_mode="$2"
    local file_path="$3"

    if ! command -v osacompile >/dev/null 2>&1; then
        append_row "| $terminal_label | $open_mode | fail | rc=127 | osacompile is unavailable in this environment |"
        failed_cells=$((failed_cells + 1))
        total_cells=$((total_cells + 1))
        return 127
    fi

    local compiled_output
    compiled_output="$(mktemp "${TMPDIR:-/tmp}/shuttle-matrix-XXXXXX.scpt")"
    rm -f "$compiled_output"

    set +e
    local output
    output="$(osacompile -o "$compiled_output" "$file_path" 2>&1)"
    local rc=$?
    set -e

    rm -f "$compiled_output"

    output="${output//$'\n'/; }"
    if [[ -n "$output" ]]; then
        output="${output:0:220}"
    fi

    if [[ $rc -eq 0 ]]; then
        append_row "| $terminal_label | $open_mode | pass | rc=$rc | $output |"
        passed_cells=$((passed_cells + 1))
    else
        append_row "| $terminal_label | $open_mode | fail | rc=$rc | $output |"
        failed_cells=$((failed_cells + 1))
    fi

    total_cells=$((total_cells + 1))
    return $rc
}

compile_embedded_script() {
    local terminal_label="$1"
    local open_mode="$2"
    local symbol="$3"

    local template
    template="$(extract_script_source "$symbol")"
    if [[ -z "$template" ]]; then
        append_row "| $terminal_label | $open_mode | fail | rc=1 | missing template '$symbol' |"
        failed_cells=$((failed_cells + 1))
        total_cells=$((total_cells + 1))
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

    compile_applescript_file "$terminal_label" "$open_mode" "$tmp_script"
    local rc=$?
    rm -f "$tmp_script"
    return $rc
}

compile_ui_controlled_script() {
    local terminal_label="$1"
    local open_mode="$2"
    local tmp_ui_script

    tmp_ui_script="$(mktemp)"
    cat > "$tmp_ui_script" <<'EOF'
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

    compile_applescript_file "$terminal_label" "$open_mode" "$tmp_ui_script"
    local rc=$?
    rm -f "$tmp_ui_script"
    return $rc
}

run_embedded_script() {
    local terminal_label="$1"
    local open_mode="$2"
    local symbol="$3"
    shift 3

    local template
    template="$(extract_script_source "$symbol")"
    if [[ -z "$template" ]]; then
        append_row "| $terminal_label | $open_mode | fail | rc=1 | missing template '$symbol' |"
        failed_cells=$((failed_cells + 1))
        total_cells=$((total_cells + 1))
        return 1
    fi

    if ! command -v osascript >/dev/null 2>&1; then
        append_row "| $terminal_label | $open_mode | fail | rc=127 | osascript is unavailable in this environment |"
        failed_cells=$((failed_cells + 1))
        total_cells=$((total_cells + 1))
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
    local script_output
    script_output="$(run_osascript_with_timeout "$tmp_script" "$@" 2>&1)"
    local rc=$?
    set -e
    rm -f "$tmp_script"

    script_output="${script_output//$'\n'/; }"
    if [[ -n "$script_output" ]]; then
        script_output="${script_output:0:220}"
    fi

    if [[ $rc -eq 0 ]]; then
        append_row "| $terminal_label | $open_mode | pass | rc=$rc | $script_output |"
        passed_cells=$((passed_cells + 1))
    else
        append_row "| $terminal_label | $open_mode | fail | rc=$rc | $script_output |"
        failed_cells=$((failed_cells + 1))
    fi

    total_cells=$((total_cells + 1))
    return $rc
}

run_ui_controlled_terminal() {
    local terminal_label="$1"
    local terminal_name="$2"
    local open_mode="$3"
    local command_text="$4"

    if ! command -v osascript >/dev/null 2>&1; then
        append_row "| $terminal_label | $open_mode | fail | rc=127 | osascript is unavailable in this environment |"
        failed_cells=$((failed_cells + 1))
        total_cells=$((total_cells + 1))
        return 127
    fi

    set +e
    local script_output
    local tmp_ui_script
    tmp_ui_script="$(mktemp)"
    cat > "$tmp_ui_script" <<'EOF'
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
    script_output="$(run_osascript_with_timeout "$tmp_ui_script" "$terminal_name" "$command_text" "$open_mode" 2>&1)"
    local rc=$?
    rm -f "$tmp_ui_script"
    set -e

    script_output="${script_output//$'\n'/; }"
    if [[ -n "$script_output" ]]; then
        script_output="${script_output:0:220}"
    fi

    if [[ $rc -eq 0 ]]; then
        append_row "| $terminal_label | $open_mode | pass | rc=$rc | $script_output |"
        passed_cells=$((passed_cells + 1))
    else
        append_row "| $terminal_label | $open_mode | fail | rc=$rc | $script_output |"
        failed_cells=$((failed_cells + 1))
    fi

    total_cells=$((total_cells + 1))
    return $rc
}

echo "# Terminal Parity Matrix Capture" > "$REPORT_FILE"
echo "Date (UTC): $DATE_UTC" >> "$REPORT_FILE"
echo "Host macOS: $(sw_vers -productVersion)" >> "$REPORT_FILE"
echo "Interactive mode: $INTERACTIVE_MATRIX" >> "$REPORT_FILE"
echo >> "$REPORT_FILE"

echo "1) Preflight checks" | tee -a "$REPORT_FILE"
set +e
"$ROOT_DIR/tests/terminal_parity_resource_check.sh" | tee -a "$REPORT_FILE"
resource_rc=${PIPESTATUS[0]:-0}
"$ROOT_DIR/tests/terminal_parity_probe.sh" | tee -a "$REPORT_FILE"
probe_rc=${PIPESTATUS[0]:-0}
set -e

if [[ $resource_rc -ne 0 || $probe_rc -ne 0 ]]; then
    echo "Preflight failed; matrix execution skipped." | tee -a "$REPORT_FILE"
    echo "Summary: total=$total_cells passed=$passed_cells failed=$failed_cells" | tee -a "$REPORT_FILE"
    echo "Result: BLOCKED_ENVIRONMENT" | tee -a "$REPORT_FILE"
    echo "Report: ./tests/$(basename "$REPORT_FILE")" | tee -a "$REPORT_FILE"
    exit 2
fi
echo >> "$REPORT_FILE"

echo "2) Matrix execution" >> "$REPORT_FILE"
echo "| Terminal | mode | status | result | notes |" >> "$REPORT_FILE"
echo "|---|---|---|---|---|" >> "$REPORT_FILE"

set +e
if [[ "$INTERACTIVE_MATRIX" == "1" ]]; then
    run_embedded_script "Terminal.app" "new" "terminalNewWindow" "shuttle-matrix" "basic" "$MATRIX_SMOKE_WINDOW_TITLE"
    run_embedded_script "Terminal.app" "tab" "terminalNewTabDefault" "shuttle-matrix" "basic" "$MATRIX_SMOKE_WINDOW_TITLE"
    run_embedded_script "Terminal.app" "current" "terminalCurrentWindow" "shuttle-matrix" "basic" "$MATRIX_SMOKE_WINDOW_TITLE"
    run_embedded_script "Terminal.app" "virtual" "virtualWithScreen" "shuttle-matrix" "Shuttle Matrix"

    run_embedded_script "iTerm (stable)" "new" "iTermNewWindow" "shuttle-matrix" "Default" "$MATRIX_SMOKE_WINDOW_TITLE"
    run_embedded_script "iTerm (stable)" "tab" "iTermNewTabDefault" "shuttle-matrix" "Default" "$MATRIX_SMOKE_WINDOW_TITLE"
    run_embedded_script "iTerm (stable)" "current" "iTermCurrentWindow" "shuttle-matrix" "Default" "$MATRIX_SMOKE_WINDOW_TITLE"
    run_embedded_script "iTerm (stable)" "virtual" "virtualWithScreen" "shuttle-matrix" "Shuttle Matrix"

    run_embedded_script "iTerm (nightly)" "new" "iTermNewWindow" "shuttle-matrix" "Default" "$MATRIX_SMOKE_WINDOW_TITLE"
    run_embedded_script "iTerm (nightly)" "tab" "iTermNewTabDefault" "shuttle-matrix" "Default" "$MATRIX_SMOKE_WINDOW_TITLE"
    run_embedded_script "iTerm (nightly)" "current" "iTermCurrentWindow" "shuttle-matrix" "Default" "$MATRIX_SMOKE_WINDOW_TITLE"
    run_embedded_script "iTerm (nightly)" "virtual" "virtualWithScreen" "shuttle-matrix" "Shuttle Matrix"

    run_ui_controlled_terminal "Warp" "Warp" "new" "shuttle-matrix; exit"
    run_ui_controlled_terminal "Warp" "Warp" "tab" "shuttle-matrix; exit"
    run_ui_controlled_terminal "Warp" "Warp" "current" "shuttle-matrix"
    run_embedded_script "Warp" "virtual" "virtualWithScreen" "shuttle-matrix" "Shuttle Matrix"

    run_ui_controlled_terminal "Ghostty" "Ghostty" "new" "shuttle-matrix; exit"
    run_ui_controlled_terminal "Ghostty" "Ghostty" "tab" "shuttle-matrix; exit"
    run_ui_controlled_terminal "Ghostty" "Ghostty" "current" "shuttle-matrix"
    run_embedded_script "Ghostty" "virtual" "virtualWithScreen" "shuttle-matrix" "Shuttle Matrix"
else
    compile_embedded_script "Terminal.app" "new" "terminalNewWindow"
    compile_embedded_script "Terminal.app" "tab" "terminalNewTabDefault"
    compile_embedded_script "Terminal.app" "current" "terminalCurrentWindow"
    compile_embedded_script "Terminal.app" "virtual" "virtualWithScreen"

    compile_embedded_script "iTerm (stable)" "new" "iTermNewWindow"
    compile_embedded_script "iTerm (stable)" "tab" "iTermNewTabDefault"
    compile_embedded_script "iTerm (stable)" "current" "iTermCurrentWindow"
    compile_embedded_script "iTerm (stable)" "virtual" "virtualWithScreen"

    compile_embedded_script "iTerm (nightly)" "new" "iTermNewWindow"
    compile_embedded_script "iTerm (nightly)" "tab" "iTermNewTabDefault"
    compile_embedded_script "iTerm (nightly)" "current" "iTermCurrentWindow"
    compile_embedded_script "iTerm (nightly)" "virtual" "virtualWithScreen"

    compile_ui_controlled_script "Warp" "new"
    compile_ui_controlled_script "Warp" "tab"
    compile_ui_controlled_script "Warp" "current"
    compile_embedded_script "Warp" "virtual" "virtualWithScreen"

    compile_ui_controlled_script "Ghostty" "new"
    compile_ui_controlled_script "Ghostty" "tab"
    compile_ui_controlled_script "Ghostty" "current"
    compile_embedded_script "Ghostty" "virtual" "virtualWithScreen"
fi
set -e

echo >> "$REPORT_FILE"
echo "Summary: total=${total_cells} passed=${passed_cells} failed=${failed_cells}" | tee -a "$REPORT_FILE"
echo "Result: $(if [[ $failed_cells -eq 0 ]]; then echo PASS; else echo FAIL; fi)" | tee -a "$REPORT_FILE"
echo "Report: ./tests/$(basename "$REPORT_FILE")" | tee -a "$REPORT_FILE"

if [[ $failed_cells -eq 0 ]]; then
    exit 0
else
    exit 1
fi
