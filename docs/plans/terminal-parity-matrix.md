# Terminal Parity Matrix

## Purpose
Track behavior parity for command dispatch across supported terminals and open modes on macOS 10.13+.

## Scope
- Terminals: `Terminal.app`, `iTerm (stable)`, `iTerm (nightly)`, `Warp`, `Ghostty`
- Modes: `new`, `tab`, `current`, `virtual`

## Overall Status
- `blocked` in current sandbox environment; execute matrix on interactive macOS session to produce pass/fail cell results.

## Preconditions
- App builds successfully on current branch.
- macOS Automation and Accessibility permissions are granted for tested terminal apps.
- `~/.shuttle.json` has terminal-specific test commands.
- If `.applescript` sources were changed, run `./apple-scripts/compile-all.sh` first (interactive macOS session required; sandbox/headless returns `2`).

## Quick Smoke Gate
Run resource and routing marker check before manual validation:

```bash
./apple-scripts/compile-all.sh
./tests/terminal_parity_resource_check.sh
```

## Matrix

| Terminal | new | tab | current | virtual | Notes |
|---|---|---|---|---|---|
| Terminal.app | pending | pending | pending | pending | AppleScript-backed; app presence verified (2026-02-26 probe) |
| iTerm (stable) | pending | pending | pending | pending | AppleScript-backed; app presence verified (2026-02-26 probe) |
| iTerm (nightly) | pending | pending | pending | pending | AppleScript-backed; uses same app binary as stable; presence verified (2026-02-26 probe) |
| Warp | pending | pending | pending | pending | UI automation + virtual script path; app presence verified (2026-02-26 probe) |
| Ghostty | pending | pending | pending | pending | `open -na Ghostty.app --args -e` + virtual script path; app presence verified (2026-02-26 probe) |

Status values: `pending`, `pass`, `fail`, `blocked`

## Failure Paths
- Invalid `inTerminal` value in host entry.
- Missing or invalid `iTerm_version`.
- Missing script resource.
- Denied automation/accessibility permission.

## Execution Notes
- Record date, macOS version, and terminal version when updating the matrix.
- For each fail/blocked cell, add the exact error message and reproduction command.

## Latest Script Compile Attempt (2026-02-26, Sandbox)
- Command: `./apple-scripts/compile-all.sh`
- Outcome: `BLOCKED_ENVIRONMENT` (exit `2`)
- Error signal: AppleScript compile services reported `Connection invalid`
- Interpretation: source script recompilation must be run from an interactive macOS session.

## Latest Regression Suite Attempt (2026-02-26, Sandbox)
- Commands:
  - `./tests/regression_suite.sh`
  - `./tests/regression_suite.sh --with-compile`
- Build: `pass` (`xcodebuild` succeeded in both runs)
- Terminal preflight/probe: `pass`
- Compile step (`--with-compile`): `blocked` (exit `2`, compile services unavailable)
- Smoke step: `blocked` (`-1728`, `-10827`)
- Outcome: `REGRESSION_BLOCKED_ENVIRONMENT` (exit `2`)

## Latest Probe (2026-02-26)
- Command: `./tests/terminal_parity_probe.sh`
- macOS: `26.3`
- Preflight: `pass` (resources + routing markers present)
- App presence: `Terminal.app`, `iTerm.app`, `Warp.app`, `Ghostty.app` detected
- Outcome: `READY_FOR_MANUAL_MATRIX`

## Latest Smoke Attempt (2026-02-26, Sandbox)
- Command: `./tests/terminal_parity_smoke.sh`
- macOS: `26.3`
- Preflight checks: `pass`
- AppleScript handler invocation checks: `pass` (`rc=0` for Terminal/iTerm/virtual script dispatch)
- GUI capability checks: `fail`
  - `osascript 'tell application "Terminal" to activate'` -> `-1728` (`Can’t get application "Terminal"`)
  - `open -a /System/Applications/Utilities/Terminal.app` -> `-10827` (`kLSNoExecutableErr`)
- Outcome: `BLOCKED_ENVIRONMENT`
- Interpretation: this execution environment cannot validate live terminal behavior; matrix cell verdicts remain `pending` until run on an interactive macOS session with Automation/Accessibility permissions.
