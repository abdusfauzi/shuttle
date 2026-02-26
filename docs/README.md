# Shuttle Documentation

This folder tracks the migration of Shuttle to fully native Swift on macOS 10.13+.

## Documentation Structure

### Tier 1: Getting Started
- [00-getting-started.md](./00-getting-started.md): Main entry point and reading order.
- [README.md](./README.md): Quick index of all docs.

### Tier 2: Core Documentation
- [01-requirements.md](./01-requirements.md)
- [02-architecture.md](./02-architecture.md)
- [03-database-schema.md](./03-database-schema.md)
- [04-api-specifications.md](./04-api-specifications.md)
- [05-components.md](./05-components.md)
- [06-permissions.md](./06-permissions.md)
- [07-navigation.md](./07-navigation.md)
- [08-implementation-phases.md](./08-implementation-phases.md)
- [09-file-changes.md](./09-file-changes.md)
- [10-testing.md](./10-testing.md)

### Tier 3: Operational Documentation
- [11-environment-config.md](./11-environment-config.md)
- [12-data-seeding.md](./12-data-seeding.md)
- [13-ui-design-system.md](./13-ui-design-system.md)
- [14-error-handling.md](./14-error-handling.md)
- [15-deployment-guide.md](./15-deployment-guide.md)
- [16-glossary.md](./16-glossary.md)
- [17-integration-guide.md](./17-integration-guide.md)
- [18-hooks-utilities.md](./18-hooks-utilities.md)
- [19-security-guidelines.md](./19-security-guidelines.md)
- [20-accessibility.md](./20-accessibility.md)

### Plans
- [plans/README.md](./plans/README.md)
- [plans/task-backlog.md](./plans/task-backlog.md)

## Current Snapshot
- Product: status bar SSH launcher for macOS.
- Terminal targets: Terminal.app, iTerm, Warp, Ghostty.
- Deployment target: macOS 10.13+.
- Migration state: mixed Objective-C and Swift, moving to full Swift.
- Terminal routing state: backend strategy isolation implemented in `TerminalRouter`; parity matrix execution in progress.
- Launch-at-login state: active runtime path is Swift (`LaunchAtLoginController.swift`); legacy Objective-C files are retained only for cleanup/fallback.
