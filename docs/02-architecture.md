# 02 - Architecture

## Current Architecture (Transition State)
- Entry point: `main.m` + `NSApplicationMain`.
- App lifecycle + menu orchestration: `AppDelegate.swift` (new primary path).
- Legacy/interop components in Objective-C:
  - `LaunchAtLoginController.{h,m}`
  - `AboutWindowController.{h,m}`
- Resources:
  - AppleScript bundles under `Shuttle/apple-scpt/`
  - Default config `Shuttle/shuttle.default.json`

## Target Architecture (Fully Swift)
- `AppDelegate.swift`: only lifecycle wiring.
- `ConfigService.swift`: JSON/path load, schema checks, defaults.
- `SSHConfigParser.swift`: parse and merge ssh config hosts.
- `MenuBuilder.swift`: deterministic menu tree rendering.
- `TerminalRouter.swift`: route command to terminal backend.
- `TerminalBackends/*.swift`:
  - `TerminalBackend`
  - `ITermBackend`
  - `WarpBackend`
  - `GhosttyBackend`
  - `VirtualBackend`
- `ErrorPresenter.swift`: user-facing failures.
- `LaunchAtLoginService.swift`: replace LSSharedFileList usage.

## Design Rules
- Keep side effects behind small services.
- Model config and menu entities as typed Swift structs/enums.
- Keep Objective-C bridging isolated and temporary.
