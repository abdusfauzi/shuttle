# 18 - Hooks and Utilities

## Existing Utility Patterns
- File mtime checks for hot-reload behavior.
- Regex helpers for ssh parsing and menu sort/separator tags.
- Shared AppleScript runner.

## Planned Swift Utilities
- `FileMonitor` for config mtime tracking.
- `StringEscaper` for AppleScript-safe command strings.
- `MenuNameParser` for sort/separator token handling.
- `CommandPayload` encoder/decoder replacing ad-hoc represented-object strings.

## Utility Standards
- Pure functions where possible.
- Deterministic output for identical inputs.
- Unit tests for all parsing/escaping logic.
