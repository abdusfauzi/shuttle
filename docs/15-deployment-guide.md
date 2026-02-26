# 15 - Deployment Guide

## Pre-Release Checklist
- Build passes on macOS target.
- AppleScript resources are up to date (`./apple-scripts/compile-all.sh` run from interactive macOS session when source scripts changed).
- Entitlements and signing are valid.
- Terminal matrix smoke tests pass.
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
