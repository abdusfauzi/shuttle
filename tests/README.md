# Test Utilities

- `path_hygiene_check.sh`: ensures docs/scripts do not contain hardcoded workstation paths.
- `terminal_parity_resource_check.sh`: verifies required compiled `.scpt` resources and terminal-routing markers.
- `terminal_parity_probe.sh`: verifies preflight and installed terminal app presence/version.
- `terminal_parity_smoke.sh`: runs preflight + AppleScript handler dispatch + GUI capability checks.
- `regression_suite.sh`: one-shot regression runner for path hygiene + parity scripts + `xcodebuild`.
  - Use `./tests/regression_suite.sh --with-compile` to include `./apple-scripts/compile-all.sh` at the start.
