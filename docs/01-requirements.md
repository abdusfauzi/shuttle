# 01 - Requirements

## Functional Requirements
- Shuttle launches from macOS status bar and renders host menus from config.
- Shuttle reads hosts from:
  - `~/.shuttle.json` (or custom path via `~/.shuttle.path`)
  - `~/.ssh/config` and `/etc/ssh_config` (when enabled)
- Shuttle executes command targets in supported terminals:
  - Terminal.app
  - iTerm (stable/nightly modes)
  - Warp
  - Ghostty
- `inTerminal` routing supports: `new`, `tab`, `current`, `virtual`.
- Menu supports nested groups, sort tags, separator tags, and per-item metadata (`theme`, `title`).

## Migration Requirements
- Minimum OS support: macOS 10.13.
- Target architecture: fully native Swift source for app logic.
- Objective-C allowed only temporarily during phased migration.
- Existing user config format remains backward compatible.

## Non-Functional Requirements
- Startup should remain near-instant for typical configs.
- Failures must surface clear user-facing error dialogs.
- Security posture must not regress (automation permissions, command execution hygiene).

## Acceptance Criteria
- `AppDelegate` behavior parity validated by tests/manual matrix.
- All active app logic files compiled as Swift.
- Build pipeline produces signed app with entitlements.
- Terminal matrix passes smoke + regression tests.
