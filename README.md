# Shuttle

A menu bar SSH launcher for macOS.

Shuttle loads hosts from JSON and SSH config files, then opens commands in your configured terminal.

## Project Status

This repository is actively being modernized.

- Platform target is now macOS `10.13+`.
- Terminal support has been expanded and normalized.
- Runtime migration to native Swift is in place for the active build target.
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

### Documentation Overhaul
A full documentation set has been added to support implementation and migration work:

- Start here: [`docs/00-getting-started.md`](./docs/00-getting-started.md)
- Index: [`docs/README.md`](./docs/README.md)
- Migration plan: [`docs/08-implementation-phases.md`](./docs/08-implementation-phases.md)
- Testing matrix: [`docs/10-testing.md`](./docs/10-testing.md)
- Planning backlog: [`docs/plans/task-backlog.md`](./docs/plans/task-backlog.md)

## Config Notes

Key config fields in `~/.shuttle.json`:

- `terminal`: `Terminal.app`, `Terminal`, `iTerm`, `Warp`, `Ghostty`
- `iTerm_version`: `stable` or `nightly`
- `open_in`: `new`, `tab`, `current`, `virtual`
- `show_ssh_config_hosts`: `true`/`false`

Default reference config is available at [`Shuttle/shuttle.default.json`](./Shuttle/shuttle.default.json).

## Build From Source

```bash
xcodebuild -project Shuttle.xcodeproj -scheme Shuttle -configuration Debug -sdk macosx -derivedDataPath /tmp/ShuttleDerivedData build
```

If you modify AppleScript sources under `apple-scripts/`, rebuild compiled script resources with:

```bash
./apple-scripts/compile-all.sh
```

Run the consolidated regression checks with:

```bash
./tests/regression_suite.sh
```

Notes:
- In restricted environments, use `-derivedDataPath` (as shown) to avoid permission issues with default Xcode paths.
- Terminal automation may require Apple Events and Accessibility permissions.
- `./apple-scripts/compile-all.sh` expects an interactive macOS session; it returns exit code `2` when AppleScript compile services are unavailable (sandbox/headless).
- `./tests/regression_suite.sh` returns exit code `2` when interactive automation validation is blocked by the environment.

## Repository Layout

- [`Shuttle/`](./Shuttle/) - App source, resources, plist, entitlements
- [`Shuttle.xcodeproj/`](./Shuttle.xcodeproj/) - Xcode project
- [`apple-scripts/`](./apple-scripts/) - AppleScript source and compile helpers (`compile-all.sh` is the canonical entrypoint)
- [`tests/`](./tests/) - Sample config/test fixtures
- [`docs/`](./docs/) - Core and operational documentation

## Credits

Original project by [Trevor Fitzgerald](https://github.com/fitztrev).

Inspired by [SSHMenu](http://sshmenu.sourceforge.net/).
