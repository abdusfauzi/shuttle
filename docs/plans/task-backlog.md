# Task Backlog

## Purpose
This is the canonical, easy-to-scan backlog for Shuttle migration and delivery work.

## Usage Rules
- Use this file as the single source of truth for active tasks.
- Update task rows immediately when status changes.
- Use `YYYY-MM-DD` for all date fields.
- Keep completed items in the completed log; do not delete history.

## Status Legend
- `todo`: Not started.
- `in_progress`: Actively being worked.
- `blocked`: Cannot progress due to dependency or external constraint.
- `done`: Completed and verified.
- `deferred`: Intentionally postponed.

## Priority Legend
- `P0`: Critical path, blocks release/migration.
- `P1`: High priority, near-critical.
- `P2`: Important but not release-blocking.
- `P3`: Nice-to-have or optimization.

## Active Tasks

| ID | Task | Phase | Status | Priority | Owner | Target | Dependencies | Last Updated | Notes |
|---|---|---|---|---|---|---|---|---|---|
| M-002 | Extract `ConfigService`, `SSHConfigParser`, `MenuBuilder`, `TerminalRouter` from `AppDelegate.swift` | Phase 2 | done | P0 | unassigned | 2026-03-05 | M-001 | 2026-02-26 | Implemented in `Shuttle/AppServices.swift`, with `AppDelegate.swift` reduced to orchestration and action wiring. |
| M-003 | Implement terminal backend isolation strategy for Terminal.app, iTerm, Warp, Ghostty, Virtual | Phase 3 | done | P0 | unassigned | 2026-03-12 | M-002 | 2026-02-26 | `TerminalRouter` now dispatches through terminal-specific backend strategy types with centralized mode normalization. |
| M-004 | Execute full terminal behavior parity matrix across all open modes and supported terminals | Testing | blocked | P0 | unassigned | 2026-03-14 | M-003 | 2026-02-26 | Matrix runbook added at `docs/plans/terminal-parity-matrix.md`; probe/smoke/regression scripts confirm current sandbox lacks GUI automation (`-1728`, `-10827`). Requires interactive macOS run with Automation/Accessibility permissions to unblock. |
| M-005 | Retire remaining Objective-C path for launch-at-login and remove bridging header | Phase 4 | done | P1 | unassigned | 2026-03-19 | M-002, M-003 | 2026-02-26 | Active target now uses `LaunchAtLoginController.swift` and `main.swift`; Objective-C app/launch sources and bridging header are removed from build graph. |
| M-006 | Cleanup and hardening: remove stale resources, finalize regression coverage, release checklist | Phase 5 | in_progress | P2 | unassigned | 2026-03-25 | M-004, M-005 | 2026-02-26 | Legacy Objective-C runtime files and old bridging/prefix headers removed; AppleScript compile helpers are now root-relative (`./apple-scripts/compile-all.sh`) and stale duplicate script sources are removed. Added `./tests/regression_suite.sh` as a one-shot preflight/smoke/build runner with blocked-environment signaling and `./tests/path_hygiene_check.sh` for workstation-path guardrails. Updated stale XIB metadata from `AppDelegate.h` reference to `AppDelegate.swift`. |

## Blockers and Risks
- Launch-at-login still relies on deprecated `LSSharedFileList*` APIs (now wrapped in Swift for macOS 10.13 compatibility) and should migrate to ServiceManagement with helper architecture in a future major change.
- Terminal automation paths may fail without Apple Events and Accessibility permissions.
- UI-driven automation for Warp/Ghostty has higher fragility than scriptable interfaces.
- M-004 is currently blocked in this execution environment due unavailable GUI automation (`osascript`/`open -a Terminal.app` failures: `-1728`, `-10827`).

## Completed Log (Newest First)
- 2026-02-26: Normalized all `apple-scripts/compile-*.sh` helpers to project-root relative paths, added canonical `apple-scripts/compile-all.sh` with explicit blocked-environment signaling (exit `2`), and removed stale duplicate directory `apple-scripts/iTermStable copy`.
- 2026-02-26: Added `tests/regression_suite.sh` to run parity preflight, smoke, and build checks in one command; returns exit `2` when automation constraints block interactive validation.
- 2026-02-26: Executed `tests/regression_suite.sh` and `tests/regression_suite.sh --with-compile`; both produced `REGRESSION_BLOCKED_ENVIRONMENT` in sandbox while preserving successful `xcodebuild` validation.
- 2026-02-26: Updated stale Objective-C source metadata in `MainMenu.xib` (`./Classes/AppDelegate.h`) to Swift source reference (`./AppDelegate.swift`) for base and Spanish localizations.
- 2026-02-26: Added `tests/path_hygiene_check.sh` and integrated it into `tests/regression_suite.sh` to prevent regressions with hardcoded workstation paths.
- 2026-02-26: Legacy Objective-C runtime files (`main.m`, `AppDelegate.m/.h`, `LaunchAtLoginController.m/.h`, `AboutWindowController.m/.h`) and obsolete bridge/prefix headers were removed from repository after Swift-only target validation.
- 2026-02-26: M-005 completed. Active build graph is Swift-only (`main.swift`, `AppDelegate.swift`, services/controllers in Swift); Objective-C app runtime sources are no longer in target sources and bridging header is removed from build settings.
- 2026-02-26: M-003 completed. Isolated terminal dispatch via backend strategy objects in `TerminalRouter` for Terminal.app, iTerm (stable/nightly), Warp, and Ghostty; build validated on macOS `10.13` target.
- 2026-02-26: M-005 started. Added Swift launch-at-login controller, switched source compilation from Objective-C implementation, and removed active bridging header build settings.
- 2026-02-26: M-002 completed. Extracted `ConfigService`, `SSHConfigParser`, `MenuBuilder`, and `TerminalRouter` to `Shuttle/AppServices.swift`; build validated on macOS 10.13 target.
- 2026-02-25: M-001 (Phase 1 baseline) completed. Swift/Objective-C bridging compile blockers resolved; `AppDelegate.swift` compiles and build succeeds on macOS `10.13` target.
- 2026-02-25: `AboutWindowController` migrated to Swift and compiled from `AboutWindowController.swift`.

## Decision Log
- 2026-02-25: Canonical backlog file is `docs/plans/task-backlog.md` to centralize look-back references.
- 2026-02-25: Scope remains backlog-only reorganization; numbered docs (`08`, `09`, `10`) stay in place.
- 2026-02-25: Default owner value is `unassigned` until explicit assignment.
- 2026-02-26: Continue migration with modular service extraction first, then tighten terminal parity behavior as next iteration.
- 2026-02-26: Terminal routing follows backend strategy objects to reduce branching and keep new terminal integrations isolated from `AppDelegate`.
- 2026-02-26: Launch-at-login runtime path is now Swift-first; bridging header is no longer required by target build settings.
- 2026-02-26: Swift `main.swift` is the active entrypoint; Objective-C `main.m`, `AppDelegate.m`, and Objective-C launch-at-login source are removed from the target build graph.
- 2026-02-26: Terminal parity execution is tracked in `docs/plans/terminal-parity-matrix.md` with a repeatable preflight check script.
- 2026-02-26: Added `tests/terminal_parity_probe.sh` and logged first environment probe in the terminal matrix to gate manual parity execution.
- 2026-02-26: Added `tests/terminal_parity_smoke.sh`; sandbox run confirms automation/GUI launch is blocked (`-1728`, `-10827`), so manual parity matrix remains pending for interactive macOS execution.
- 2026-02-26: AppleScript compile tooling is root-relative (`./apple-scripts/compile-all.sh`) to avoid workstation-specific path coupling.

## Next Review Checkpoint
- Date: 2026-03-03
- Focus: Run M-004 matrix on interactive macOS session to clear blocked state, then complete release hardening (M-006).
