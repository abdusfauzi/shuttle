#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

latest_matrix_file=$(ls "$ROOT_DIR"/tests/terminal-parity-matrix-capture-*.md 2>/dev/null | sort | tail -n 1 || true)

if [[ -z "$latest_matrix_file" ]]; then
    echo "INFO: No terminal parity matrix capture file found."
    echo "Result: SKIP"
    exit 0
fi

result_ok=$(rg -q --pcre2 "^Result:\\s*PASS" "$latest_matrix_file" && echo yes || echo no)
cell_ok=$(rg -q --pcre2 "^Summary:\\s*total=20\\s+passed=20" "$latest_matrix_file" && echo yes || echo no)

if [[ "$result_ok" == "yes" ]] && ([[ "$cell_ok" == "yes" ]] || rg -q --pcre2 "Cells:\s*20/20" "$latest_matrix_file"); then
    echo "OK: Latest matrix capture passed: $latest_matrix_file"
    echo "Result: PASS"
else
    echo "FAIL: Latest matrix capture is incomplete or not passing: $latest_matrix_file" >&2
    echo "Result: FAIL"
    exit 1
fi
