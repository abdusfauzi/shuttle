# 15 - Deployment Guide

## Pre-Release Checklist
- `./tests/path_hygiene_check.sh` passes.
- Build passes on macOS target.
- Minimum supported macOS target is `13.0`.
- AppleScript resources are up to date (`./apple-scripts/compile-all.sh` run from interactive macOS session when source scripts changed).
- Entitlements and signing are valid.
- `./tests/regression_suite.sh` completes with `REGRESSION_PASS` (or `REGRESSION_BLOCKED_ENVIRONMENT` only in known sandbox contexts).
- Clean signed release build footprint check passes (`rm -rf /tmp/ShuttleSignedBuild` then `./tests/release_bundle_size_check.sh`).
- First-run onboarding preflight validates required setup:
  - Missing permissions/config show the setup card before shortcut execution.
  - `Open Privacy Settings` opens Security/Privacy panes.
  - `Open Config` opens the active Shuttle config file.
  - After granting requirements, SSH shortcuts run without onboarding block.
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
