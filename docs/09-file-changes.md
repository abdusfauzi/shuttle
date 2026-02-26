# 09 - File Changes

## Current Key Files
- `Shuttle/main.swift` (active Swift app entrypoint)
- `Shuttle/AppDelegate.swift` (new Swift app logic)
- `Shuttle/AppServices.swift` (service layer for config, SSH parsing, menu build, terminal routing + backend dispatch strategy)
- `Shuttle/LaunchAtLoginController.swift` (active Swift launch-at-login implementation)
- `Shuttle/AppDelegate.m` (legacy file retained; no longer in target sources)
- `Shuttle/LaunchAtLoginController.{h,m}` (legacy files retained; no longer in target sources)
- `Shuttle/AboutWindowController.swift` (active Swift implementation)
- `Shuttle/AboutWindowController.{h,m}` (legacy ObjC files retained, no longer built)
- `Shuttle/Shuttle-Bridging-Header.h`
- `Shuttle/shuttle.default.json`
- `Shuttle.xcodeproj/project.pbxproj`

## Planned Migration Map
- `AppDelegate.m` -> removed from target sources (completed); delete file in cleanup phase.
- `LaunchAtLoginController.{h,m}` -> `LaunchAtLoginController.swift` (completed for active build path); delete legacy files in cleanup phase.
- `AboutWindowController.{h,m}` -> `AboutWindowController.swift`.
- `Shuttle-Bridging-Header.h` -> removed from build settings and project references; keep file on disk until final Objective-C cleanup.
- `AppDelegate.swift` -> slim orchestration only (completed for current runtime path).
- `TerminalRouter` -> keep backend-per-terminal isolation and extend via dedicated backend types only.

## File Change Governance
- One migration phase per pull request.
- Keep rollback-safe commits by preserving feature parity at each phase boundary.
