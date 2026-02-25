# 17 - Integration Guide

## Terminal Integration Strategy
- Terminal.app and iTerm: prefer script-based control using bundled `.scpt` assets.
- Warp: UI automation fallback via AppleScript/System Events.
- Ghostty: launch via `open -na Ghostty.app --args -e <command>`.

## Integration Constraints
- Some integrations depend on user-granted automation/accessibility permissions.
- iTerm behavior differs between stable and nightly.

## Future Improvements
- Prefer direct terminal APIs where available.
- Reduce reliance on simulated keystrokes.
