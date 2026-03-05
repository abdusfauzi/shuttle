#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$ROOT_DIR/Shuttle/apple-scpt"
DATE_UTC="$(date -u +%F_%H-%M-%SZ)"
REPORT_FILE="$ROOT_DIR/tests/terminal-parity-matrix-capture-${DATE_UTC}.md"

if [[ ! -x "$ROOT_DIR/tests/terminal_parity_resource_check.sh" || ! -x "$ROOT_DIR/tests/terminal_parity_probe.sh" ]]; then
    echo "FAIL: required parity scripts are not executable" >&2
    exit 1
fi

append_row() {
    local row="$1"
    echo "$row" | tee -a "$REPORT_FILE"
}

run_osascript_file() {
    local terminal_label="$1"
    local open_mode="$2"
    local script_path="$3"
    shift 3

    set +e
    local script_output
    script_output="$(osascript "$script_path" "$@" 2>&1)"
    local rc=$?
    set -e

    script_output="${script_output//$'\n'/; }"
    if [[ -n "$script_output" ]]; then
        script_output="${script_output:0:220}"
    fi

    if [[ $rc -eq 0 ]]; then
        append_row "| $terminal_label | $open_mode | pass | rc=$rc | $script_output |"
    else
        append_row "| $terminal_label | $open_mode | fail | rc=$rc | $script_output |"
    fi
}

run_ui_controlled_terminal() {
    local terminal_label="$1"
    local terminal_name="$2"
    local open_mode="$3"
    local command_text="$4"

    set +e
    local script_output
    script_output="$(osascript - "$terminal_name" "$command_text" "$open_mode" <<'EOF'
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
    )"
    local rc=$?
    set -e

    script_output="${script_output//$'\n'/; }"
    if [[ -n "$script_output" ]]; then
        script_output="${script_output:0:220}"
    fi

    if [[ $rc -eq 0 ]]; then
        append_row "| $terminal_label | $open_mode | pass | rc=$rc | $script_output |"
    else
        append_row "| $terminal_label | $open_mode | fail | rc=$rc | $script_output |"
    fi
}

echo "# Terminal Parity Matrix Capture" > "$REPORT_FILE"
echo "Date (UTC): $DATE_UTC" >> "$REPORT_FILE"
echo "Host macOS: $(sw_vers -productVersion)" >> "$REPORT_FILE"
echo >> "$REPORT_FILE"

echo "1) Preflight checks" | tee -a "$REPORT_FILE"
"$ROOT_DIR/tests/terminal_parity_resource_check.sh" | tee -a "$REPORT_FILE"
"$ROOT_DIR/tests/terminal_parity_probe.sh" | tee -a "$REPORT_FILE"
echo >> "$REPORT_FILE"

echo "2) Matrix execution" >> "$REPORT_FILE"
echo "| Terminal | mode | status | result | notes |" >> "$REPORT_FILE"
echo "|---|---|---|---|---|" >> "$REPORT_FILE"

run_osascript_file "Terminal.app" "new" "$SCRIPT_DIR/terminal-new-window.scpt" "shuttle-matrix" "basic" "Shuttle Matrix"
run_osascript_file "Terminal.app" "tab" "$SCRIPT_DIR/terminal-new-tab-default.scpt" "shuttle-matrix" "basic" "Shuttle Matrix"
run_osascript_file "Terminal.app" "current" "$SCRIPT_DIR/terminal-current-window.scpt" "shuttle-matrix" "basic" "Shuttle Matrix"
run_osascript_file "Terminal.app" "virtual" "$SCRIPT_DIR/virtual-with-screen.scpt" "shuttle-matrix" "Shuttle Matrix"

run_osascript_file "iTerm (stable)" "new" "$SCRIPT_DIR/iTerm2-stable-new-window.scpt" "shuttle-matrix" "Default" "Shuttle Matrix"
run_osascript_file "iTerm (stable)" "tab" "$SCRIPT_DIR/iTerm2-stable-new-tab-default.scpt" "shuttle-matrix" "Default" "Shuttle Matrix"
run_osascript_file "iTerm (stable)" "current" "$SCRIPT_DIR/iTerm2-stable-current-window.scpt" "shuttle-matrix" "Default" "Shuttle Matrix"
run_osascript_file "iTerm (stable)" "virtual" "$SCRIPT_DIR/virtual-with-screen.scpt" "shuttle-matrix" "Shuttle Matrix"

run_osascript_file "iTerm (nightly)" "new" "$SCRIPT_DIR/iTerm2-nightly-new-window.scpt" "shuttle-matrix" "Default" "Shuttle Matrix"
run_osascript_file "iTerm (nightly)" "tab" "$SCRIPT_DIR/iTerm2-nightly-new-tab-default.scpt" "shuttle-matrix" "Default" "Shuttle Matrix"
run_osascript_file "iTerm (nightly)" "current" "$SCRIPT_DIR/iTerm2-nightly-current-window.scpt" "shuttle-matrix" "Default" "Shuttle Matrix"
run_osascript_file "iTerm (nightly)" "virtual" "$SCRIPT_DIR/virtual-with-screen.scpt" "shuttle-matrix" "Shuttle Matrix"

run_ui_controlled_terminal "Warp" "Warp" "new" "shuttle-matrix"
run_ui_controlled_terminal "Warp" "Warp" "tab" "shuttle-matrix"
run_ui_controlled_terminal "Warp" "Warp" "current" "shuttle-matrix"
run_osascript_file "Warp" "virtual" "$SCRIPT_DIR/virtual-with-screen.scpt" "shuttle-matrix" "Shuttle Matrix"

run_ui_controlled_terminal "Ghostty" "Ghostty" "new" "shuttle-matrix"
run_ui_controlled_terminal "Ghostty" "Ghostty" "tab" "shuttle-matrix"
run_ui_controlled_terminal "Ghostty" "Ghostty" "current" "shuttle-matrix"
run_osascript_file "Ghostty" "virtual" "$SCRIPT_DIR/virtual-with-screen.scpt" "shuttle-matrix" "Shuttle Matrix"

echo >> "$REPORT_FILE"
echo "Report: $REPORT_FILE"
