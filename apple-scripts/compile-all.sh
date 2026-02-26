#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Compiling Shuttle AppleScripts into Shuttle/apple-scpt..."
"$ROOT_DIR/apple-scripts/compile-Terminal.sh"
"$ROOT_DIR/apple-scripts/compile-iTermStable.sh"
"$ROOT_DIR/apple-scripts/compile-iTermNightly.sh"
"$ROOT_DIR/apple-scripts/compile-Virtual.sh"
"$ROOT_DIR/apple-scripts/compile-WarpStable.sh"
echo "Done."
