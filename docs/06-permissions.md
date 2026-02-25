# 06 - Permissions

## Required macOS Permissions
- Apple Events automation permission for controlling Terminal/iTerm/Warp.
- Accessibility permission may be required for UI keystroke-driven automation paths.

## App Configuration
- Keep `NSAppleEventsUsageDescription` in `Shuttle-Info.plist` accurate and user-readable.
- Keep entitlements aligned with signing requirements.

## Migration Notes
- Ghostty and Warp UI automation should fail gracefully with actionable guidance.
- Prefer deterministic app scripting interfaces over simulated keystrokes when possible.
