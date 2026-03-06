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
- Quote and validate shell command arguments derived from user-provided config and SSH input.
- Run `./tests/security_review_check.sh` in each regression cycle.

## Migration Security Work
- Audit all command construction points.
- Replace string concatenation with typed command payload models.
- Add tests for escaping and malformed inputs.
- Security review documentation is maintained in [`docs/21-security-review.md`](./21-security-review.md).
