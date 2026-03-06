# 17 - Integration Guide

## Terminal Integration Strategy
- Terminal.app and iTerm: use Swift-hosted AppleScript template sources embedded in `TerminalScriptCatalog`.
- Warp: UI automation fallback via AppleScript/System Events.
- Ghostty: launch via `open` + guarded `--args -e` when needed, with UI-controlled fallback path when Automation permission is available.

## Integration Constraints
- Some integrations depend on user-granted automation/accessibility permissions.
- iTerm behavior differs between stable and nightly.

## Future Improvements
- Prefer direct terminal APIs where available.
- Reduce reliance on simulated keystrokes.
