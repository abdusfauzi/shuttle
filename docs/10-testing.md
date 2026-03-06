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
- `./apple-scripts/compile-all.sh` (run only when maintaining legacy `.applescript` sources; requires interactive macOS session, may return `2` in sandbox/headless environments)
- `./tests/terminal_parity_resource_check.sh`
- `./tests/terminal_parity_probe.sh`
- `./tests/terminal_parity_smoke.sh` (compile-only/non-invasive by default; set `TERMINAL_PARITY_INTERACTIVE_SMOKE=1` for real terminal launches)
- `./tests/url_launch_detection_check.sh`
- `./tests/launch_at_login_crash_guard.sh`
- `./tests/ghostty_launch_policy_check.sh`
- `./tests/terminal_parity_matrix_check.sh` (checks latest matrix report for PASS status and full cell completion)
- `./tests/terminal_parity_matrix_capture.sh` (compile-only/non-invasive by default; set `TERMINAL_PARITY_INTERACTIVE_MATRIX=1` for real terminal launches)
- `./tests/regression_suite.sh` (runs path hygiene + parity preflight + smoke + build; returns `2` if environment blocks GUI automation)
- `./tests/security_review_check.sh` (verifies command-safety checks and security guard presence in source flow)

Current state (2026-03-06):
- Backend isolation is implemented in `TerminalRouter`; full matrix execution (M-004) is complete with `20/20` pass in interactive macOS.
- `./tests/regression_suite.sh` is available for one-shot preflight/smoke/build checks and now uses non-invasive parity tooling by default to avoid permission prompts and stray terminal windows during normal runs.
- `./tests/terminal_parity_probe.sh` now captures installed terminal versions to strengthen matrix evidence logging.
- `./tests/security_review_check.sh` and the security review pass are now part of `./tests/regression_suite.sh` as part of the hardening track.

## Failure Path Tests
- Missing/invalid `iTerm_version` value.
- Invalid `inTerminal` value.
- Missing embedded script template in `TerminalScriptCatalog`.
- Denied automation/accessibility permission.
- Denied automation/accessibility permission.

## CI/Automation Plan
- Add unit tests for parser/menu/router services.
- Add lightweight integration smoke script for command dispatch.
