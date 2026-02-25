# 19 - Security Guidelines

## Threat Surface
- User-provided shell commands from JSON and ssh config.
- Apple Events and UI automation privileges.
- Import/export operations touching filesystem.

## Security Controls
- Never execute hidden commands implicitly; actions must be menu-triggered.
- Validate terminal mode and iTerm version values strictly.
- Escape strings passed into AppleScript.
- Show clear warning when permissions are missing.

## Migration Security Work
- Audit all command construction points.
- Replace string concatenation with typed command payload models.
- Add tests for escaping and malformed inputs.
