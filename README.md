# Shuttle

A menu bar SSH launcher for macOS.

Shuttle loads hosts from JSON and SSH config files, then opens commands in your configured terminal.

## Project Status

This repository is actively being modernized.

- Platform target is now macOS `10.13+`.
- Terminal support has been expanded and normalized.
- Runtime migration to native Swift is in place for the active build target.
- Optional runtime diagnostics are available for migration/performance verification (`SHUTTLE_DIAGNOSTICS=1`).
- Full migration and operational documentation now lives under [`docs/`](./docs/).

## What Changed

### New and Updated Terminal Support
- `Terminal.app` (native macOS Terminal)
- `iTerm` (stable and nightly modes)
- `Warp`
- `Ghostty`

### Migration Direction
- Primary app flow is now Swift-native.
- Objective-C runtime components have been retired from the active target build graph.
- Backward compatibility for existing `~/.shuttle.json` config is preserved during migration.
- `AppDelegate.swift` is now orchestration-focused; config/menu/terminal logic has been extracted into Swift services.
- Terminal dispatch now uses backend strategy routing for easier parity maintenance and future terminal additions.
- Launch-at-login now compiles from `LaunchAtLoginController.swift` (bridging header no longer required by target build settings).
- Active target runtime path is now Swift-only (`main.swift` + Swift app/services/controllers).
- Setup/onboarding now routes into a centered native Settings window instead of a blocking alert.
- Settings now owns permissions, config location, SSH-config import toggle, and About metadata in one place.

### Documentation Overhaul
A full documentation set has been added to support implementation and migration work:

- Start here: [`docs/00-getting-started.md`](./docs/00-getting-started.md)
- Index: [`docs/README.md`](./docs/README.md)
- Migration plan: [`docs/08-implementation-phases.md`](./docs/08-implementation-phases.md)
- Testing matrix: [`docs/10-testing.md`](./docs/10-testing.md)
- Planning backlog: [`docs/plans/task-backlog.md`](./docs/plans/task-backlog.md)
- Security review report: [`docs/21-security-review.md`](./docs/21-security-review.md)

## Config Notes

Shuttle resolves the active config in this order:

- user-selected config file stored by bookmark (`Settings -> Choose Config File`)
- compatibility path marker in `~/.shuttle.path`
- local default `~/.shuttle.json`

The selected config file can live anywhere, including iCloud Drive, and Shuttle uses it in place as the active source of truth.

Settings also includes explicit copy actions when you want both locations populated:

- `Copy Local Default To...` copies `~/.shuttle.json` to another destination such as iCloud Drive
- `Copy Active To Local Default` copies the currently selected config back into `~/.shuttle.json`

Key config fields in the active `.shuttle.json`:

- `terminal`: `Terminal.app`, `Terminal`, `iTerm`, `Warp`, `Ghostty`
- `iTerm_version`: `stable` or `nightly`
- `open_in`: `new`, `tab`, `current`, `virtual`
- `show_ssh_config_hosts`: `true`/`false`

Default reference config is available at [`Shuttle/shuttle.default.json`](./Shuttle/shuttle.default.json).

## Build From Source

```bash
xcodebuild -project Shuttle.xcodeproj -scheme Shuttle -configuration Debug -sdk macosx -derivedDataPath /tmp/ShuttleDerivedData build
```

If you modify AppleScript sources under `apple-scripts/` for legacy parity/reference needs, rebuild compiled script resources with:

```bash
./apple-scripts/compile-all.sh
```

Run the consolidated regression checks with:

```bash
./tests/regression_suite.sh
```

Build, developer-sign when a local signing identity is available, install to `/Applications/Shuttle.app`, and relaunch with:

```bash
./scripts/install_local_app.sh
```

Run real terminal-launch parity checks only when you explicitly want interactive validation:

```bash
TERMINAL_PARITY_INTERACTIVE_SMOKE=1 ./tests/terminal_parity_smoke.sh
TERMINAL_PARITY_INTERACTIVE_MATRIX=1 ./tests/terminal_parity_matrix_capture.sh
```

Enable opt-in runtime timing diagnostics during local runs with:

```bash
SHUTTLE_DIAGNOSTICS=1 /tmp/ShuttleDerivedData/Build/Products/Debug/Shuttle.app/Contents/MacOS/Shuttle
```

Run path hygiene checks directly with:

```bash
./tests/path_hygiene_check.sh
```

Notes:
- In restricted environments, use `-derivedDataPath` (as shown) to avoid permission issues with default Xcode paths.
- Terminal automation may require Apple Events and Accessibility permissions.
- For stable Accessibility trust on local installs, prefer `./scripts/install_local_app.sh` over copying an ad-hoc build bundle by hand.
- On first run, incomplete setup now opens the Settings window with direct actions for Accessibility, Automation, and config selection.
- If Shuttle was previously granted Accessibility as an older ad-hoc build, remove it from Accessibility and add `/Applications/Shuttle.app` again after installing a developer-signed build.
- Terminal parity smoke/matrix scripts are non-invasive by default; real terminal launches now require explicit interactive opt-in flags.
- `./apple-scripts/compile-all.sh` expects an interactive macOS session; it returns exit code `2` when AppleScript compile services are unavailable (sandbox/headless).
- `./tests/regression_suite.sh` returns exit code `2` when interactive automation validation is blocked by the environment.
- `SHUTTLE_DIAGNOSTICS=1` emits opt-in timing logs for config snapshot load, menu build, and terminal dispatch without changing app behavior.

## Repository Layout

- [`Shuttle/`](./Shuttle/) - App source, resources, plist, entitlements
- [`Shuttle.xcodeproj/`](./Shuttle.xcodeproj/) - Xcode project
- [`apple-scripts/`](./apple-scripts/) - AppleScript source/reference artifacts and compile helpers (`compile-all.sh` for compatibility checks)
- [`scripts/`](./scripts/) - Local build/install helpers, including developer-signed installation to `/Applications`
- [`tests/`](./tests/) - Sample config/test fixtures
- [`docs/`](./docs/) - Core and operational documentation

## Credits

Original project by [Trevor Fitzgerald](https://github.com/fitztrev).

Inspired by [SSHMenu](http://sshmenu.sourceforge.net/).
