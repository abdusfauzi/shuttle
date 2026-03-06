# 15 - Deployment Guide

## Pre-Release Checklist
- `./tests/path_hygiene_check.sh` passes.
- Build passes on macOS target.
- Minimum supported macOS target is `10.13`.
- AppleScript runtime logic is embedded in `Shuttle/AppServices.swift`.
- Run `./apple-scripts/compile-all.sh` from an interactive macOS session only when legacy `.applescript` artifacts are edited for archival/reference parity.
- Entitlements and signing are valid.
- `./tests/regression_suite.sh` completes with `REGRESSION_PASS` (or `REGRESSION_BLOCKED_ENVIRONMENT` only in known sandbox contexts).
- Clean release build footprint check passes (`xcodebuild -project Shuttle.xcodeproj -scheme Shuttle -configuration Release -sdk macosx -derivedDataPath /tmp/ShuttleSignedBuild build` then `./tests/release_bundle_size_check.sh`).
- For macOS `10.13`, embedded `libswift*.dylib` files in `Contents/Frameworks` are expected; the footprint check guards for unexpected non-Swift frameworks and bundle-size regression instead of requiring zero frameworks.
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
