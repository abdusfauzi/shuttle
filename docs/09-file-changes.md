# 09 - File Changes

## Current Key Files
- `Shuttle/AppDelegate.swift` (new Swift app logic)
- `Shuttle/AppServices.swift` (service layer for config, SSH parsing, menu build, terminal routing)
- `Shuttle/AppDelegate.m` (legacy logic still present)
- `Shuttle/LaunchAtLoginController.{h,m}`
- `Shuttle/AboutWindowController.swift` (active Swift implementation)
- `Shuttle/AboutWindowController.{h,m}` (legacy ObjC files retained, no longer built)
- `Shuttle/Shuttle-Bridging-Header.h`
- `Shuttle/shuttle.default.json`
- `Shuttle.xcodeproj/project.pbxproj`

## Planned Migration Map
- `AppDelegate.m` -> remove after parity confirmation.
- `LaunchAtLoginController.{h,m}` -> `LaunchAtLoginService.swift`.
- `AboutWindowController.{h,m}` -> `AboutWindowController.swift`.
- `Shuttle-Bridging-Header.h` -> remove once ObjC retirement is complete.
- `AppDelegate.swift` -> slim orchestration only.

## File Change Governance
- One migration phase per pull request.
- Keep rollback-safe commits by preserving feature parity at each phase boundary.
