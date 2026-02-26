# Terminal Parity Matrix

## Purpose
Track behavior parity for command dispatch across supported terminals and open modes on macOS 10.13+.

## Scope
- Terminals: `Terminal.app`, `iTerm (stable)`, `iTerm (nightly)`, `Warp`, `Ghostty`
- Modes: `new`, `tab`, `current`, `virtual`

## Preconditions
- App builds successfully on current branch.
- macOS Automation and Accessibility permissions are granted for tested terminal apps.
- `~/.shuttle.json` has terminal-specific test commands.

## Quick Smoke Gate
Run resource and routing marker check before manual validation:

```bash
./tests/terminal_parity_resource_check.sh
```

## Matrix

| Terminal | new | tab | current | virtual | Notes |
|---|---|---|---|---|---|
| Terminal.app | pending | pending | pending | pending | AppleScript-backed; app presence verified (2026-02-26 probe) |
| iTerm (stable) | pending | pending | pending | pending | AppleScript-backed; app presence verified (2026-02-26 probe) |
| iTerm (nightly) | pending | pending | pending | pending | AppleScript-backed; uses same app binary as stable; presence verified (2026-02-26 probe) |
| Warp | pending | pending | pending | pending | UI automation + virtual script path; app presence verified (2026-02-26 probe) |
| Ghostty | pending | pending | pending | pending | `open -na Ghostty.app --args -e` + virtual script path; app presence verified (2026-02-26 probe) |

Status values: `pending`, `pass`, `fail`, `blocked`

## Failure Paths
- Invalid `inTerminal` value in host entry.
- Missing or invalid `iTerm_version`.
- Missing script resource.
- Denied automation/accessibility permission.

## Execution Notes
- Record date, macOS version, and terminal version when updating the matrix.
- For each fail/blocked cell, add the exact error message and reproduction command.

## Latest Probe (2026-02-26)
- Command: `./tests/terminal_parity_probe.sh`
- macOS: `26.3`
- Preflight: `pass` (resources + routing markers present)
- App presence: `Terminal.app`, `iTerm.app`, `Warp.app`, `Ghostty.app` detected
- Outcome: `READY_FOR_MANUAL_MATRIX`
