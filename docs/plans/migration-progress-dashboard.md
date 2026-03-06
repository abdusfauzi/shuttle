# Migration Progress Dashboard

## Scope
- **Product**: Shuttle macOS Swift migration and terminal support modernization.
- **Target baseline**: macOS `10.13+` runtime target.
- **Core objective**: native Swift-only app runtime with parity across Terminal.app, iTerm, Warp, and Ghostty.

## Current Completion Snapshot (2026-03-06)

| Area | Progress | Evidence |
|---|---:|---|
| Migration planning and task control | 100% | `task-backlog.md` contains all active migration entries and is updated on every transition. |
| Swift runtime migration | 100% | Active app sources are Swift-only; active source set contains `main.swift`, `AppDelegate.swift`, and Swift service files. |
| Terminal backend parity | 100% | Latest capture evidence is `tests/terminal-parity-matrix-capture-2026-03-05_23-43-13Z.md` (`20/20` pass). |
| Security hardening | 100% | `tests/security_review_check.sh` integrated into `tests/regression_suite.sh` and passing. |
| Tooling and release checks | 98% | Regression suite passes; warning-only deprecations remain from 10.13-compatible legacy login-item compatibility path. |

## Known Balance Items (Remaining Focus, Not Blockers)

1. **Stability polish**
   - Reduce legacy launch-at-login surface where possible while preserving 10.13 support.
2. **Safety/robustness hardening**
   - Keep deprecation-sensitive legacy paths isolated and monitor for OS behavior drift.
3. **Performance confidence**
   - Add lightweight runtime telemetry and optional startup timing around config/menu build and terminal dispatch paths.

## Timeline

| Date | Milestone | State | Owner | Notes |
|---|---|---|---|---|
| 2026-03-05 | Terminal matrix capture completed | done | App | `20/20` matrix validation in `terminal-parity-matrix-capture-2026-03-05_23-43-13Z.md`. |
| 2026-03-06 | Security hardening sweep completed | done | App | New security checks integrated in regression loop. |
| 2026-03-06 | Launch-at-login deprecation-risk containment | partial | App | Legacy path kept for 10.13 compatibility; unsafe sentinel conversion removed; still API-deprecated warnings. |
| 2026-03-06+ | Balance closeout | in-progress | App | Execute balance items above and archive as needed. |

## How to Interpret Progress
- `100%` means implementation and regression evidence are in place.
- `98%` areas are production-safe but still have legacy API or measurement follow-up.
- Any timeline entry marked `in-progress` should be expanded into explicit backlog rows before execution.
