# 10 - Testing

## Manual Smoke Tests
- Launch app and open menu.
- Validate host tree rendering from JSON.
- Enable ssh host import and validate dedupe/ignore behavior.
- Test import/export config actions.
- Test configure action with default and custom editor.

## Terminal Matrix
Test each mode (`new`, `tab`, `current`, `virtual`) across:
- Terminal.app
- iTerm (stable)
- iTerm (nightly)
- Warp
- Ghostty

Tracking document:
- `docs/plans/terminal-parity-matrix.md`

Quick preflight:
- `./tests/terminal_parity_resource_check.sh`
- `./tests/terminal_parity_probe.sh`

Current state (2026-02-26):
- Backend isolation is implemented in `TerminalRouter`; matrix execution is active work for M-004.

## Failure Path Tests
- Missing/invalid `iTerm_version` value.
- Invalid `inTerminal` value.
- Missing script resource.
- Denied automation/accessibility permission.

## CI/Automation Plan
- Add unit tests for parser/menu/router services.
- Add lightweight integration smoke script for command dispatch.
