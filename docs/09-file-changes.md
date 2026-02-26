# 09 - File Changes

## Current Key Files
- `Shuttle/main.swift` (active Swift app entrypoint)
- `Shuttle/AppDelegate.swift` (new Swift app logic)
- `Shuttle/AppServices.swift` (service layer for config, SSH parsing, menu build, terminal routing + backend dispatch strategy)
- `Shuttle/LaunchAtLoginController.swift` (active Swift launch-at-login implementation)
- `Shuttle/AboutWindowController.swift` (active Swift implementation)
- `Shuttle/shuttle.default.json`
- `Shuttle.xcodeproj/project.pbxproj`

## Planned Migration Map
- Legacy Objective-C app runtime files (`main.m`, `AppDelegate.m`, `LaunchAtLoginController.{h,m}`, `AboutWindowController.{h,m}`) -> removed (completed).
- `Shuttle-Bridging-Header.h` and prefix header references -> removed from build configuration and repository (completed).
- `AppDelegate.swift` -> slim orchestration only (completed for current runtime path).
- `TerminalRouter` -> keep backend-per-terminal isolation and extend via dedicated backend types only.

## File Change Governance
- One migration phase per pull request.
- Keep rollback-safe commits by preserving feature parity at each phase boundary.
