# 08 - Implementation Phases

## Objective
Finish migration to fully Swift code while preserving compatibility and terminal support on macOS 10.13+.

## Known Blockers (Current)
- Launch-at-login still uses deprecated `LSSharedFileList*` APIs (now wrapped in Swift for 10.13 compatibility).
- Terminal behavior parity tests are still pending for full mode matrix (`new/tab/current/virtual`) across all supported terminals.
- In restricted environments, build may require explicit derived data path.

## Progress Snapshot (2026-02-26)
- `AppDelegate.swift` compiles as the active app flow.
- `main.swift` is now the active app entrypoint.
- Swift/Objective-C bridging compile blockers are resolved.
- `AboutWindowController` has been ported to Swift and is now compiled from `AboutWindowController.swift`.
- Project builds successfully with macOS deployment target `10.13`.
- Core service extraction is in place via `Shuttle/AppServices.swift` (`ConfigService`, `SSHConfigParser`, `MenuBuilder`, `TerminalRouter`).
- Phase 3 routing refactor is in place: `TerminalRouter` dispatches through terminal-specific backend strategy types for Terminal.app, iTerm, Warp, and Ghostty.
- Launch-at-login path compiles from `LaunchAtLoginController.swift`; Objective-C app runtime sources and bridging-header build setting are removed from active target configuration.
- Legacy Objective-C runtime source files and obsolete bridge/prefix headers have been removed from the repository.

## Phase 0 - Baseline and Stabilize
- Lock deployment target to 10.13.
- Confirm `AppDelegate.swift` is primary runtime path.
- Track current compile blockers and runtime regressions.

Exit criteria:
- Debug build succeeds.
- Existing user config still works.

## Phase 1 - Bridge Hardening
- Fix bridging header/tooling issues.
- Keep Objective-C classes callable from Swift with minimal surface.
- Add smoke test checklist for menu open and command dispatch.

Exit criteria:
- Swift compile clean with bridging header.
- No crash on app launch/menu open.

## Phase 2 - Service Extraction
- Extract from `AppDelegate.swift`:
  - `ConfigService`
  - `SSHConfigParser`
  - `MenuBuilder`
  - `TerminalRouter`
- Replace dynamic containers with typed Swift models.

Exit criteria:
- `AppDelegate.swift` reduced to orchestration and action wiring.
- Unit coverage on extracted services.

## Phase 3 - Terminal Backend Isolation
- Implement backend strategy objects per terminal.
- Normalize open modes (`new/tab/current/virtual`) centrally.
- Keep behavior parity for iTerm stable/nightly.

Exit criteria:
- Matrix pass for Terminal/iTerm/Warp/Ghostty.
- New terminal support can be added without touching AppDelegate.

## Phase 4 - Objective-C Retirement
- Replace `LaunchAtLoginController` with Swift implementation compatible with 10.13.
- Port `AboutWindowController` to Swift.
- Remove bridging header.

Exit criteria:
- No Objective-C source required for app logic.
- Build settings no longer include bridging header.

## Phase 5 - Cleanup and Hardening
- Remove dead scripts and stale resources.
- Add regression tests and release checklist.
- Update changelog and user docs.

Exit criteria:
- Fully Swift code path in production.
- Release candidate signed and validated.
