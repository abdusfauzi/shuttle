# 09 - File Changes

## Current Key Files
- `Shuttle/main.swift` (active Swift app entrypoint)
- `Shuttle/AppDelegate.swift` (new Swift app logic)
- `Shuttle/AppServices.swift` (service layer for config, SSH parsing, menu build, terminal routing + backend dispatch strategy)
- `Shuttle/SettingsWindowController.swift` (active Settings/permissions/config UI controller)
- `Shuttle/LaunchAtLoginController.swift` (active Swift launch-at-login implementation)
- `Shuttle/AboutWindowController.swift` (retained legacy About controller code path; About content is now surfaced through Settings)
- `apple-scripts/compile-all.sh` (canonical AppleScript compile entrypoint)
- `Shuttle/shuttle.default.json`
- `Shuttle.xcodeproj/project.pbxproj`
- `docs/21-security-review.md` (security review and residual risk record)
- `tests/security_review_check.sh` (security regression guard script)

## Planned Migration Map
- Legacy Objective-C app runtime files (`main.m`, `AppDelegate.m`, `LaunchAtLoginController.{h,m}`, `AboutWindowController.{h,m}`) -> removed (completed).
- `Shuttle-Bridging-Header.h` and prefix header references -> removed from build configuration and repository (completed).
- `AppDelegate.swift` -> slim orchestration only (completed for current runtime path).
- `TerminalRouter` -> keep backend-per-terminal isolation and extend via dedicated backend types only.
- AppleScript compile scripts -> normalized to project-root relative paths (completed).
- `apple-scripts/iTermStable copy` duplicate source directory -> removed as stale resource (completed).
- `Shuttle/*/MainMenu.xib` stale Objective-C metadata (`./Classes/AppDelegate.h`) -> updated to Swift source reference (`./AppDelegate.swift`) (completed).
- About/menu onboarding -> replaced by a centered Settings window with bookmark-backed config selection (completed).

## File Change Governance
- One migration phase per pull request.
- Keep rollback-safe commits by preserving feature parity at each phase boundary.
