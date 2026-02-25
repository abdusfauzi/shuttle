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
| M-002 | Extract `ConfigService`, `SSHConfigParser`, `MenuBuilder`, `TerminalRouter` from `AppDelegate.swift` | Phase 2 | in_progress | P0 | unassigned | 2026-03-05 | M-001 | 2026-02-25 | Keep behavior parity while replacing dynamic containers with typed Swift models. |
| M-003 | Implement terminal backend isolation strategy for Terminal.app, iTerm, Warp, Ghostty, Virtual | Phase 3 | todo | P0 | unassigned | 2026-03-12 | M-002 | 2026-02-25 | Centralize open-mode routing (`new/tab/current/virtual`) and reduce terminal-specific branching in app delegate. |
| M-004 | Execute full terminal behavior parity matrix across all open modes and supported terminals | Testing | blocked | P0 | unassigned | 2026-03-14 | M-003 | 2026-02-25 | Blocked until backend isolation is implemented; then run smoke + failure-path matrix from `docs/10-testing.md`. |
| M-005 | Retire remaining Objective-C path for launch-at-login and remove bridging header | Phase 4 | todo | P1 | unassigned | 2026-03-19 | M-002, M-003 | 2026-02-25 | Replace `LaunchAtLoginController.{h,m}` with Swift service compatible with macOS 10.13+. |
| M-006 | Cleanup and hardening: remove stale resources, finalize regression coverage, release checklist | Phase 5 | todo | P2 | unassigned | 2026-03-25 | M-004, M-005 | 2026-02-25 | Close documentation and changelog gaps and finalize release readiness. |

## Blockers and Risks
- `LaunchAtLoginController` still relies on deprecated `LSSharedFileList*` APIs and remains Objective-C.
- Terminal automation paths may fail without Apple Events and Accessibility permissions.
- UI-driven automation for Warp/Ghostty has higher fragility than scriptable interfaces.

## Completed Log (Newest First)
- 2026-02-25: M-001 (Phase 1 baseline) completed. Swift/Objective-C bridging compile blockers resolved; `AppDelegate.swift` compiles and build succeeds on macOS `10.13` target.
- 2026-02-25: `AboutWindowController` migrated to Swift and compiled from `AboutWindowController.swift`.

## Decision Log
- 2026-02-25: Canonical backlog file is `docs/plans/task-backlog.md` to centralize look-back references.
- 2026-02-25: Scope remains backlog-only reorganization; numbered docs (`08`, `09`, `10`) stay in place.
- 2026-02-25: Default owner value is `unassigned` until explicit assignment.

## Next Review Checkpoint
- Date: 2026-03-01
- Focus: Confirm M-002 service extraction boundaries, update dependencies and status, and re-evaluate M-004 blocker.
