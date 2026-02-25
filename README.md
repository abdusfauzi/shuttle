# Shuttle

A menu bar SSH launcher for macOS.

Shuttle loads hosts from JSON and SSH config files, then opens commands in your configured terminal.

## Project Status

This repository is actively being modernized.

- Platform target is now macOS `10.13+`.
- Terminal support has been expanded and normalized.
- Migration to fully native Swift is in progress (currently mixed Swift + Objective-C).
- Full migration and operational documentation now lives under [`docs/`](./docs/).

## What Changed

### New and Updated Terminal Support
- `Terminal.app` (native macOS Terminal)
- `iTerm` (stable and nightly modes)
- `Warp`
- `Ghostty`

### Migration Direction
- Primary app flow is moving into Swift.
- Objective-C components are being retired in phases.
- Backward compatibility for existing `~/.shuttle.json` config is preserved during migration.

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

Notes:
- In restricted environments, use `-derivedDataPath` (as shown) to avoid permission issues with default Xcode paths.
- Terminal automation may require Apple Events and Accessibility permissions.

## Repository Layout

- [`Shuttle/`](./Shuttle/) - App source, resources, plist, entitlements
- [`Shuttle.xcodeproj/`](./Shuttle.xcodeproj/) - Xcode project
- [`apple-scripts/`](./apple-scripts/) - AppleScript source and compile helpers
- [`tests/`](./tests/) - Sample config/test fixtures
- [`docs/`](./docs/) - Core and operational documentation

## Credits

Original project by [Trevor Fitzgerald](https://github.com/fitztrev).

Inspired by [SSHMenu](http://sshmenu.sourceforge.net/).
