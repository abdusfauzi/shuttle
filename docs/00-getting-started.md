# 00 - Getting Started

## Goal
Deliver Shuttle as a fully Swift macOS app (10.13+) while preserving behavior and adding stable support for Terminal.app, iTerm, Warp, and Ghostty.

## Read This First
1. [01-requirements.md](./01-requirements.md)
2. [02-architecture.md](./02-architecture.md)
3. [08-implementation-phases.md](./08-implementation-phases.md)
4. [10-testing.md](./10-testing.md)
5. [plans/task-backlog.md](./plans/task-backlog.md)

## Repository Landmarks
- `Shuttle/`: app source files, resources, scripts, plist, entitlements.
- `Shuttle.xcodeproj/`: project file and build settings.
- `apple-scripts/`: source AppleScript files and compile helpers.
- `tests/`: sample JSON/config payloads.
- `docs/`: migration and operational docs.

## Immediate Priorities
- Keep current terminal behavior stable.
- Complete terminal parity matrix validation across supported terminals and open modes.
- Replace fragile script execution paths with typed Swift services.
- Enforce acceptance criteria per migration phase.
