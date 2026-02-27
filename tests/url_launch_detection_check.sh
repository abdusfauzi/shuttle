#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/Shuttle/AppServices.swift"

if /usr/bin/grep -q "return URL(string: command)" "$SOURCE_FILE"; then
    echo "FAIL: raw URL(string: command) detection is still present." >&2
    echo "This can misclassify shell commands (e.g. 'ssh user@host') as URLs." >&2
    exit 1
fi

if ! /usr/bin/grep -q "contains(\"://\")" "$SOURCE_FILE"; then
    echo "FAIL: strict URL-scheme detection guard not found." >&2
    exit 1
fi

echo "OK: URL launch detection is guarded to explicit scheme URLs."
