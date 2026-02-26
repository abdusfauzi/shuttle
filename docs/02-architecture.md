# 02 - Architecture

## Current Architecture
- Entry point: `main.swift` + `NSApplicationMain`.
- App lifecycle + menu orchestration: `AppDelegate.swift`.
- Services:
  - `ConfigService`
  - `SSHConfigParser`
  - `MenuBuilder`
  - `TerminalRouter` + backend strategy implementations
- Launch-at-login runtime path: `LaunchAtLoginController.swift`.
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
- Keep runtime paths Swift-native and avoid reintroducing Objective-C bridging dependencies.
