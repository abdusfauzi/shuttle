# Terminal Parity Matrix

## Purpose
Track behavior parity for command dispatch across supported terminals and open modes on macOS 10.13+.

## Scope
- Terminals: `Terminal.app`, `iTerm (stable)`, `iTerm (nightly)`, `Warp`, `Ghostty`
- Modes: `new`, `tab`, `current`, `virtual`

## Overall Status
- `completed`: parity matrix captured successfully for all terminals and modes in an interactive macOS session.

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

When running in an interactive automation-capable machine, capture the full matrix with:

```bash
./tests/terminal_parity_matrix_capture.sh
```

## Matrix

| Terminal | new | tab | current | virtual | Notes |
|---|---|---|---|---|---|
| Terminal.app | pass | pass | pass | pass | 2026-03-06 capture pass |
| iTerm (stable) | pass | pass | pass | pass | 2026-03-06 capture pass |
| iTerm (nightly) | pass | pass | pass | pass | 2026-03-06 capture pass |
| Warp | pass | pass | pass | pass | 2026-03-06 capture pass |
| Ghostty | pass | pass | pass | pass | 2026-03-06 capture pass |

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
- Path hygiene gate: `pass` (`./tests/path_hygiene_check.sh`)
- Build: `pass` (`xcodebuild` succeeded in both runs)
- Terminal preflight/probe: `pass`
- Compile step (`--with-compile`): `blocked` (exit `2`, compile services unavailable)
- Smoke step: `blocked` (`-1728`, `-10827`)
- Outcome: `REGRESSION_BLOCKED_ENVIRONMENT` (exit `2`)

## Latest Probe (2026-02-26)
- Command: `./tests/terminal_parity_probe.sh`
- macOS: `26.3`
- Preflight: `pass` (resources + routing markers present)
- App presence:
  - `Terminal.app` `2.15 (466)`
  - `iTerm.app` `3.6.6 (3.6.6)`
  - `Warp.app` `0.2026.02.18.08.22.02 (0.2026.02.18.08.22.02)`
  - `Ghostty.app` `1.2.3 (12214)`
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

## Latest Smoke Attempt (2026-02-26, Interactive macOS)
- Command: `./tests/terminal_parity_smoke.sh`
- Host macOS: `26.3`
- Preflight checks: `pass`
- GUI capability checks: `pass`
  - `osascript 'tell application "Terminal" to activate'` -> `rc=0`
  - `open -a /System/Applications/Utilities/Terminal.app` -> `rc=0`
- AppleScript handler invocation checks: `pass` (`rc=0` for Terminal/iTerm/virtual script dispatch)
- Outcome: `MANUAL_MATRIX_REQUIRED`
- Interpretation: environment is capable of automation; next step is filling parity matrix cells with per-terminal/per-mode behavioral verification evidence.

## Latest Matrix Capture (2026-03-06, Interactive macOS)
- Command: `./tests/terminal_parity_matrix_capture.sh`
- Report: `./tests/terminal-parity-matrix-capture-2026-03-05_23-43-13Z.md`
- Host macOS: `26.3.1`
- Result: `PASS`
- Cells: `20/20`

## Latest Regression Suite Attempt (2026-02-26, Interactive macOS)
- Command: `./tests/regression_suite.sh`
- Path hygiene gate: `pass`
- Terminal preflight/probe: `pass`
- Smoke step: `pass` (`MANUAL_MATRIX_REQUIRED`)
- Build: `pass` (`xcodebuild` succeeded)
- Outcome: `REGRESSION_PASS`

## Manual Matrix Execution Checklist
- Precondition: run `./tests/regression_suite.sh` with `MANUAL_MATRIX_REQUIRED` and ensure Terminal, iTerm (stable/nightly), Warp, Ghostty automation/config permissions are granted.
- Sequence:
  - Terminal.app: `new`, `tab`, `current`, `virtual`
  - iTerm stable: `new`, `tab`, `current`, `virtual`
  - iTerm nightly: `new`, `tab`, `current`, `virtual`
  - Warp: `new`, `tab`, `current`, `virtual`
  - Ghostty: `new`, `tab`, `current`, `virtual`
- For each cell:
  - capture observed command launch target
  - capture failure reason if any
  - log: timestamp, macOS build, terminal version, and evidence text
- Update matrix status values as `pass`/`fail`/`blocked` and add exact error message in notes.
