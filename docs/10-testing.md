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
- `./tests/path_hygiene_check.sh` (ensures docs/scripts stay free of hardcoded workstation paths)
- `./apple-scripts/compile-all.sh` (run when `.applescript` sources change; requires interactive macOS session, may return `2` in sandbox/headless environments)
- `./tests/terminal_parity_resource_check.sh`
- `./tests/terminal_parity_probe.sh`
- `./tests/terminal_parity_smoke.sh`
- `./tests/regression_suite.sh` (runs path hygiene + parity preflight + smoke + build; returns `2` if environment blocks GUI automation)

Current state (2026-02-26):
- Backend isolation is implemented in `TerminalRouter`; full matrix execution (M-004) is currently blocked in sandbox/non-interactive environments and must run on interactive macOS with automation permissions.
- `./tests/regression_suite.sh` is available for one-shot preflight/smoke/build checks and currently returns blocked status in sandboxed runs where GUI automation is unavailable.
- `./tests/terminal_parity_probe.sh` now captures installed terminal versions to strengthen matrix evidence logging.

## Failure Path Tests
- Missing/invalid `iTerm_version` value.
- Invalid `inTerminal` value.
- Missing script resource.
- Denied automation/accessibility permission.

## CI/Automation Plan
- Add unit tests for parser/menu/router services.
- Add lightweight integration smoke script for command dispatch.
