# 15 - Deployment Guide

## Pre-Release Checklist
- `./tests/path_hygiene_check.sh` passes.
- Build passes on macOS target.
- AppleScript resources are up to date (`./apple-scripts/compile-all.sh` run from interactive macOS session when source scripts changed).
- Entitlements and signing are valid.
- `./tests/regression_suite.sh` completes with `REGRESSION_PASS` (or `REGRESSION_BLOCKED_ENVIRONMENT` only in known sandbox contexts).
- Migration phase acceptance criteria met.

## Release Steps
1. Update version in plist/changelog.
2. Build release artifact.
3. Sign app and verify entitlements.
4. Run post-sign smoke tests.
5. Publish binary and release notes.

## Rollback
- Keep previous stable binary available.
- Roll back if terminal dispatch or config parsing regresses.
