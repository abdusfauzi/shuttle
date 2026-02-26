#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/apple-scripts/virtual"
OUTPUT_DIR="$ROOT_DIR/Shuttle/apple-scpt"
COMMON_LIB="$ROOT_DIR/apple-scripts/lib/compile-common.sh"

source "$COMMON_LIB"

mkdir -p "$OUTPUT_DIR"

echo "Compiling AppleScripts for virtual mode..."
compile_script "$OUTPUT_DIR/virtual-with-screen.scpt" "$SOURCE_DIR/virtual-with-screen.applescript"
