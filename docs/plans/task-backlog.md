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
| M-004 | Execute full terminal behavior parity matrix across all open modes and supported terminals | Testing | done | P0 | unassigned | 2026-03-14 | M-003 | 2026-03-06 | Matrix capture completed in interactive macOS session with all 20/20 cells passing across Terminal, iTerm stable/nightly, Warp, and Ghostty. Evidence: `tests/terminal-parity-matrix-capture-2026-03-05_23-43-13Z.md`. |
| M-005 | Retire remaining Objective-C path for launch-at-login and remove bridging header | Phase 4 | done | P1 | unassigned | 2026-03-19 | M-002, M-003 | 2026-02-26 | Active target now uses `LaunchAtLoginController.swift` and `main.swift`; Objective-C app/launch sources and bridging header are removed from build graph. |
| M-006 | Cleanup and hardening: remove stale resources, finalize regression coverage, release checklist | Phase 5 | done | P2 | unassigned | 2026-03-25 | M-004, M-005 | 2026-03-06 | Legacy Objective-C runtime files and old bridging/prefix headers removed; AppleScript compile helpers are now root-relative (`./apple-scripts/compile-all.sh`) and stale duplicate script sources are removed. Added `./tests/regression_suite.sh` as a one-shot preflight/smoke/build runner with blocked-environment signaling and `./tests/path_hygiene_check.sh` for workstation-path guardrails. Updated stale XIB metadata from `AppDelegate.h` reference to `AppDelegate.swift`. Added `docs/plans/release-checklist.md` and refreshed `CHANGELOG.md` Unreleased migration notes. Hardened `tests/path_hygiene_check.sh` by replacing user-specific workstation paths with portable regex-style patterns. |
| M-007 | Archive deprecated legacy scripts and old runtime artifacts for migration completion | Phase 5 | done | P3 | unassigned | 2026-03-20 | M-006 | 2026-03-06 | Migrated inactive legacy Warp AppleScript sources and compile helpers into `archive/legacy-scripts/`, removed legacy Warp `.scpt` outputs from active resource set, and updated compile/test policy to exclude archived scripts from active flow. |
| M-008 | Align docs/changelog with current runtime behavior and platform baseline | Documentation | done | P2 | unassigned | 2026-03-06 | M-007 | 2026-03-06 | Updated `docs/17-integration-guide.md` and `CHANGELOG.md` to remove stale `open -na` guidance and correct target/pending entries. |
| M-009 | Complete in-depth security review and patch identified command-safety gaps for host, editor, and terminal launches | Security | done | P1 | unassigned | 2026-03-06 | M-008 | 2026-03-06 | Added threat model, command-handling review, and remediation in Swift command safety paths. |
| M-010 | Quarantine SSH host aliases before composing terminal commands | Security/Hardening | done | P1 | unassigned | 2026-03-06 | M-009 | 2026-03-06 | Implemented alias validation and shell-safe quoting for SSH-derived `cmd` entries to prevent command injection through host names. |
| M-011 | Add security review automation checks to regression gate | Testing/Security | done | P2 | unassigned | 2026-03-06 | M-010 | 2026-03-06 | Added `docs/21-security-review.md`, `tests/security_review_check.sh`, and integrated the check into `tests/regression_suite.sh`. |
| M-012 | Add matrix evidence verification step to regression suite and docs | Testing/Quality | done | P2 | unassigned | 2026-03-06 | M-011 | 2026-03-06 | Added `tests/terminal_parity_matrix_check.sh` and integrated it into `tests/regression_suite.sh`, docs, and release checklist so parity matrix capture evidence is validated as part of the automated loop. |
| M-013 | Add terminal script execution failure propagation in router error path | Security/Stability | done | P1 | unassigned | 2026-03-06 | M-012 | 2026-03-06 | Router now treats missing/failed AppleScript dispatch as an actionable error instead of silent no-op and returns `runHost` feedback through the existing error handler. |
| M-014 | Extend security regression coverage for launch policy and fallback paths | Security | done | P1 | unassigned | 2026-03-06 | M-013 | 2026-03-06 | Added regression coverage for URL-launch detection, launch-at-login pointer-safety, and Ghostty launch-policy fallback checks to the security step in `regression_suite.sh`. |
| M-015 | Remove `.scpt` dependency from runtime/parity tooling and align checks on embedded templates | Testing/Hardening | done | P0 | unassigned | 2026-03-06 | M-013, M-014 | 2026-03-06 | Updated `Shuttle.xcodeproj` to remove packaged `.scpt` references, switched parity resource checks to inspect embedded `TerminalScriptCatalog` templates, and updated `terminal_parity_smoke.sh`/`terminal_parity_matrix_capture.sh` to execute against Swift-hosted script sources.
| M-016 | Stabilize parity check execution under non-interactive AppleScript constraints | Testing/Hardening | done | P1 | unassigned | 2026-03-06 | M-015 | 2026-03-06 | Added bounded execution wrappers for embedded-template checks, made matrix cell execution continue under `set -e`, and normalized captured report paths to avoid workstation-absolute strings.
| M-017 | Publish migration progress dashboard and timeline tracking | Documentation/Operations | done | P2 | unassigned | 2026-03-20 | M-016 | 2026-03-06 | Added `docs/plans/migration-progress-dashboard.md`, linked it in planning docs, and documented the current completion state and remaining balance focus areas.
| M-018 | Add optional Swift-native runtime diagnostics for migration confidence | Performance/Operations | done | P2 | unassigned | 2026-03-06 | M-017 | 2026-03-06 | Added `RuntimeDiagnostics` timing hooks for config snapshot load, menu build, and terminal dispatch. Added `tests/runtime_diagnostics_check.sh` and integrated it into `./tests/regression_suite.sh`. |
| M-019 | Isolate macOS 10.13-compatible launch-at-login APIs behind a dedicated compatibility helper | Stability/Compatibility | done | P1 | unassigned | 2026-03-06 | M-018 | 2026-03-06 | Deprecated `LSSharedFileList*` usage is now confined to `LegacyLoginItemStore` inside `LaunchAtLoginController.swift`. Added `tests/launch_at_login_isolation_check.sh` and integrated it into `./tests/regression_suite.sh`. |

## Blockers and Risks
- Terminal automation paths may fail without Apple Events and Accessibility permissions.
- UI-driven automation for Warp/Ghostty has higher fragility than scriptable interfaces.
- `~/.shuttle.path` content and SSH alias input remain editable by user; malformed values can still cause partial menu rendering failures before blocking at execution.
- Launch-at-login still relies on 10.13-compatible deprecated `LSSharedFileList` APIs, but they are now confined to `LegacyLoginItemStore` and covered by dedicated regression checks.
- Embedded template parity checks remain permission-sensitive but no longer hang in constrained environments; failures are reported as blocked/fail with deterministic outcomes.

## Completed Log (Newest First)
- 2026-03-06: Completed `M-019` by isolating deprecated login-item APIs behind `LegacyLoginItemStore` and adding `tests/launch_at_login_isolation_check.sh` to regression coverage.
- 2026-03-06: Completed `M-018` by adding opt-in runtime timing diagnostics (`SHUTTLE_DIAGNOSTICS=1`) for config load, menu build, and terminal dispatch, with regression coverage in `tests/runtime_diagnostics_check.sh`.
- 2026-03-06: Completed `M-017` by publishing `docs/plans/migration-progress-dashboard.md` and linking it into planning indexes for timeline-aware status reporting.
- 2026-03-06: Completed `M-016` by adding timeout-based script execution wrappers, non-fatal matrix progress, and absolute-path-safe report rendering in parity validation flows.
- 2026-03-06: Completed `M-015` by removing packaged `.scpt` references from the app target and migrating parity preflight/smoke/matrix scripts to use `TerminalScriptCatalog` templates in `Shuttle/AppServices.swift`.
- 2026-03-06: Completed `M-014` by adding URL launch detection/launch-at-login/Ghostty policy checks to the security gate and documenting them in test readme/docs.
- 2026-03-06: Completed `M-013` by making terminal script dispatch return explicit failure states and surfacing failures to users through `errorHandler`.
- 2026-03-06: Completed `M-011` by adding `tests/security_review_check.sh` and wiring it into `./tests/regression_suite.sh`.
- 2026-03-06: Completed `M-012` by adding `tests/terminal_parity_matrix_check.sh`, integrating it into `./tests/regression_suite.sh`, and updating release/testing docs/checklists for matrix evidence verification.
- 2026-03-06: Completed `M-010` and `M-009` security hardening pass with host-aliased SSH commands now escaped as shell-safe single-quoted arguments and command safety checks in `Shuttle/AppServices.swift`.
- 2026-03-06: Added `docs/21-security-review.md` to document threat model, residual risks, mitigation mapping, and verification evidence.
- 2026-03-06: Completed `M-008` with docs/changelog alignment for Ghostty launch behavior, macOS target baseline, and stale parity-pending entries.
- 2026-03-06: Completed `M-004` parity matrix capture in interactive macOS session; all 20 cells passed. Evidence: `tests/terminal-parity-matrix-capture-2026-03-05_23-43-13Z.md`.
- 2026-03-06: Completed `M-006` hardening scope end-to-end (cleanup, regression suite, path hygiene, and parity evidence).
- 2026-03-06: Updated `tests/terminal_parity_matrix_capture.sh` to include pass/fail counters, exit status summary, and direct embedded-template execution via `TerminalScriptCatalog`.
- 2026-03-06: Completed `M-007` archival task: moved legacy Warp helper scripts/compilers into `archive/legacy-scripts/`, removed deprecated `.applescript` and `.scpt` assets from active paths, and updated compile/test policy accordingly.
- 2026-03-06: Corrected `tests/terminal_parity_matrix_capture.sh` to load AppleScripts from the canonical project script bundle and added pass/fail counters + exit status summary output in the generated matrix report.
- 2026-03-06: Added manual execution checklist to `docs/plans/terminal-parity-matrix.md` and updated `M-004` task notes for deterministic cell-by-cell parity evidence capture.
- 2026-03-06: Added `tests/terminal_parity_matrix_capture.sh` to produce full parity matrix evidence output for 10 terminal/mode cells.
- 2026-03-06: Hardened `tests/path_hygiene_check.sh` to detect workstation-specific paths with user-agnostic patterns and remove hardcoded user directory references.
- 2026-03-06: Updated deployment target baseline from `13.0` to `10.13` in `Shuttle.xcodeproj/project.pbxproj`; aligned `tests/footprint_deployment_target_check.sh` and `docs/15-deployment-guide.md` to enforce `10.13`.
- 2026-02-26: Re-ran `tests/regression_suite.sh` in interactive macOS session; result is now `REGRESSION_PASS` with GUI capability checks returning `rc=0` for Terminal activation and launch.
- 2026-02-26: Added `docs/plans/release-checklist.md` with preconditions, automated/manual validation gates, and release decision criteria for Swift migration completion.
- 2026-02-26: Updated `CHANGELOG.md` Unreleased section to reflect Swift migration, terminal backend isolation, regression harnesses, and removed Objective-C runtime/build-bridge artifacts.
- 2026-02-26: Normalized all `apple-scripts/compile-*.sh` helpers to project-root relative paths, added canonical `apple-scripts/compile-all.sh` with explicit blocked-environment signaling (exit `2`), and removed stale duplicate directory `apple-scripts/iTermStable copy`.
- 2026-02-26: Added `tests/regression_suite.sh` to run parity preflight, smoke, and build checks in one command; returns exit `2` when automation constraints block interactive validation.
- 2026-02-26: Executed `tests/regression_suite.sh` and `tests/regression_suite.sh --with-compile`; both produced `REGRESSION_BLOCKED_ENVIRONMENT` in sandbox while preserving successful `xcodebuild` validation.
- 2026-02-26: Updated stale Objective-C source metadata in `MainMenu.xib` (`./Classes/AppDelegate.h`) to Swift source reference (`./AppDelegate.swift`) for base and Spanish localizations.
- 2026-02-26: Added `tests/path_hygiene_check.sh` and integrated it into `tests/regression_suite.sh` to prevent regressions with hardcoded workstation paths.
- 2026-02-26: Enhanced `tests/terminal_parity_probe.sh` to record terminal app versions (Terminal/iTerm/Warp/Ghostty) alongside presence for matrix evidence.
- 2026-02-26: Legacy Objective-C runtime files (`main.m`, `AppDelegate.m/.h`, `LaunchAtLoginController.m/.h`, `AboutWindowController.m/.h`) and obsolete bridge/prefix headers were removed from repository after Swift-only target validation.
- 2026-02-26: M-005 completed. Active build graph is Swift-only (`main.swift`, `AppDelegate.swift`, services/controllers in Swift); Objective-C app runtime sources are no longer in target sources and bridging header is removed from build settings.
- 2026-02-26: M-003 completed. Isolated terminal dispatch via backend strategy objects in `TerminalRouter` for Terminal.app, iTerm (stable/nightly), Warp, and Ghostty; build validated on macOS `10.13` target.
- 2026-02-26: M-005 started. Added Swift launch-at-login controller, switched source compilation from Objective-C implementation, and removed active bridging header build settings.
- 2026-02-26: M-002 completed. Extracted `ConfigService`, `SSHConfigParser`, `MenuBuilder`, and `TerminalRouter` to `Shuttle/AppServices.swift`; build validated on macOS 10.13 target.
- 2026-02-25: M-001 (Phase 1 baseline) completed. Swift/Objective-C bridging compile blockers resolved; `AppDelegate.swift` compiles and build succeeds on macOS `10.13` target.
- 2026-02-25: `AboutWindowController` migrated to Swift and compiled from `AboutWindowController.swift`.

## Decision Log
- 2026-03-06: Added `M-019` to treat 10.13 login-item compatibility as an isolation problem, not a migration blocker, and keep the deprecated surface boxed into one helper.
- 2026-03-06: Added `M-018` to close the remaining performance-confidence gap with low-risk, opt-in instrumentation instead of a persistent telemetry subsystem.
- 2026-03-06: Added `M-017` to provide a dedicated migration completion dashboard so stakeholders can answer progress questions with explicit percentages and checkpoints.
- 2026-03-06: Added `M-016` to harden parity verification against non-interactive/permission-limited environments by bounding execution and preserving deterministic failure reporting.
- 2026-03-06: Added `M-013` after a security/stability review identified silent failure paths in terminal script execution.
- 2026-03-06: Added `M-014` to enforce security regression coverage for runtime fallback and automation policy surfaces before concluding migration hardening.
- 2026-03-06: Added `M-015` to eliminate package-time `.scpt` coupling and make parity validation source-driven through Swift templates.
- 2026-03-06: Completed `M-008` to keep documentation/changelog aligned with production behavior and avoid stale operational instructions.
- 2026-03-06: Marked `M-011` complete after source-level security check automation was added to regression suite.
- 2026-03-06: Added `M-009` with a security posture that prioritizes shell-argument safety and deterministic command validation over compatibility shortcuts.
- 2026-03-06: `M-010` implemented with shell-safe SSH alias quoting to avoid command injection paths introduced via user/managed `.ssh/config`.
- 2026-03-06: Marked `M-004` complete after automated interactive matrix capture produced all-pass results in a controlled macOS session.
- 2026-03-06: Marked `M-006` complete after parity hardening, regression harness, and path-hygiene gates reached stable pass states.
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
- Date: 2026-03-06
- Focus: Monitor the isolated 10.13 login-item helper and only revisit if the deployment baseline changes.
