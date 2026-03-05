# Release Checklist

## Purpose
Final pre-release checklist for the Swift migration branch.

## Status Key
- `pending`: Not run yet.
- `pass`: Completed successfully.
- `blocked`: Could not run in current environment.
- `fail`: Completed with errors.

## Environment Preconditions
- Interactive macOS session (not headless/sandboxed).
- Automation + Accessibility permissions granted for Terminal.app, iTerm, Warp, and Ghostty.
- Local config present at `~/.shuttle.json` with terminal test commands.

## Checklist

| # | Check | Command / Action | Expected Result | Status | Notes |
|---|---|---|---|---|---|
| 1 | Path hygiene | `./tests/path_hygiene_check.sh` | No workstation-specific absolute paths in docs/scripts/tests | pass | 2026-03-06 run |
| 2 | Resource + routing preflight | `./tests/terminal_parity_resource_check.sh` | Required `.scpt` resources and routing markers present | pass | 2026-03-06 run |
| 3 | Environment probe | `./tests/terminal_parity_probe.sh` | Terminal availability + versions recorded | pass | 2026-03-06 run |
| 4 | AppleScript compile (if source changed) | `./apple-scripts/compile-all.sh` | Scripts compile; no `BLOCKED_ENVIRONMENT` | pass | 2026-03-06 run |
| 5 | Smoke parity gate | `./tests/terminal_parity_smoke.sh` | Returns `MANUAL_MATRIX_REQUIRED` in interactive environment | pass | 2026-03-06 run |
| 6 | Full regression suite | `./tests/regression_suite.sh` (and `--with-compile` when needed) | `REGRESSION_PASS` in interactive environment | pass | 2026-03-06 run; skip `--with-compile` unless script sources changed |
| 7 | Build validation | `xcodebuild -project Shuttle.xcodeproj -scheme Shuttle -configuration Debug -sdk macosx -derivedDataPath /tmp/ShuttleDerivedData build` | `** BUILD SUCCEEDED **` | pass | 2026-03-06 run |
| 8 | Manual terminal parity matrix | Follow `docs/plans/terminal-parity-matrix.md` and fill all cells | Matrix cells recorded as pass/fail/blocked with evidence | pass | `PASS` evidence: `20/20` in `tests/terminal-parity-matrix-capture-2026-03-05_23-43-13Z.md` |

## Release Decision Gate
- Release is **go** only when checks `1-8` are either `pass` or explicitly accepted as `blocked` with rationale.
- For migration completion, M-004 is now resolved from `blocked` to pass/fail evidence in an interactive macOS run.
