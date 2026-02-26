# Test Utilities

- `terminal_parity_resource_check.sh`: verifies required compiled `.scpt` resources and terminal-routing markers.
- `terminal_parity_probe.sh`: verifies preflight and installed terminal app presence.
- `terminal_parity_smoke.sh`: runs preflight + AppleScript handler dispatch + GUI capability checks.
- `regression_suite.sh`: one-shot regression runner for parity scripts plus `xcodebuild`.
  - Use `./tests/regression_suite.sh --with-compile` to include `./apple-scripts/compile-all.sh` at the start.
