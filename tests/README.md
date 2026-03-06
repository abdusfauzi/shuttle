# Test Utilities

- `path_hygiene_check.sh`: ensures docs/scripts do not contain hardcoded workstation paths.
- `security_review_check.sh`: verifies key security controls remain in place (command safety, SSH quoting, mode sanitization, editor quoting patterns).
- `runtime_diagnostics_check.sh`: verifies the optional Swift-native runtime timing hooks remain present for config loading, menu build, and terminal dispatch.
- `url_launch_detection_check.sh`: verifies URL launch detection uses explicit scheme checks instead of raw URL initialization.
- `launch_at_login_crash_guard.sh`: validates legacy launch-at-login code does not call unsafe LSSharedFileList pointer conversion.
- `ghostty_launch_policy_check.sh`: verifies Ghostty uses UI-controlled fallback and direct launch policy expectations.
- `terminal_parity_resource_check.sh`: verifies runtime script templates and terminal-routing markers in `Shuttle/AppServices.swift`.
- `terminal_parity_probe.sh`: verifies preflight and installed terminal app presence/version.
- `terminal_parity_smoke.sh`: runs preflight + AppleScript handler dispatch + GUI capability checks.
- `terminal_parity_matrix_check.sh`: verifies the latest captured matrix report exists and is marked `PASS` with full cell count.
- `regression_suite.sh`: one-shot regression runner for path hygiene + parity scripts + matrix evidence + `xcodebuild`.
  - Use `./tests/regression_suite.sh --with-compile` to include `./apple-scripts/compile-all.sh` at the start.
- `terminal_parity_matrix_capture.sh`: runs the full parity cell matrix (using embedded Swift-hosted script templates for Terminal/iTerm/virtual paths) and writes `tests/terminal-parity-matrix-capture-<timestamp>.md` with per-cell pass/fail evidence.
- `compile_all_policy_check.sh`: validates that `compile-all.sh` excludes archived legacy scripts from active flow.

Archived legacy script checks and sources are retained under:

- `archive/legacy-scripts/warp/` (Warp legacy script helpers and optional legacy compile check)
