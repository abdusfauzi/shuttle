#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT_DIR/Shuttle/AboutWindowController.swift"

grep -q "originalAuthorButton" "$SOURCE" || { echo "FAIL: original author button outlet missing" >&2; exit 1; }
grep -q "forkRepositoryButton" "$SOURCE" || { echo "FAIL: fork button outlet missing" >&2; exit 1; }
grep -q "originalAuthorButton.target = self" "$SOURCE" || { echo "FAIL: original author button target wiring missing" >&2; exit 1; }
grep -q "forkRepositoryButton.target = self" "$SOURCE" || { echo "FAIL: fork button target wiring missing" >&2; exit 1; }

echo "OK: About window button wiring guard passed."
