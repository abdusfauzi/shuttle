#!/usr/bin/env bash
set -euo pipefail

compile_script() {
    local output_path="$1"
    local source_path="$2"
    local error_output

    error_output="$(mktemp)"
    if osacompile -o "$output_path" -x "$source_path" >"$error_output" 2>&1; then
        rm -f "$error_output"
        return 0
    fi

    local rc=$?
    local compiler_stderr
    compiler_stderr="$(cat "$error_output")"
    rm -f "$error_output"

    echo "ERROR: failed to compile $source_path -> $output_path" >&2
    if [[ "$compiler_stderr" == *"Connection invalid"* ]]; then
        echo "Reason: AppleScript compile services are unavailable in this environment." >&2
        echo "Run compile scripts from an interactive macOS session (not sandboxed/headless)." >&2
        return 2
    fi

    echo "$compiler_stderr" >&2
    return "$rc"
}
