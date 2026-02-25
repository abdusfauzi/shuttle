# 14 - Error Handling

## Error Types (Target)
- `configParseFailed`
- `invalidTerminalMode`
- `invalidITermVersion`
- `scriptMissing`
- `scriptExecutionFailed`
- `permissionDenied`
- `terminalLaunchFailed`

## Handling Rules
- Convert low-level errors into typed domain errors.
- Show concise alert with clear user action.
- Terminate app only for unrecoverable startup faults.

## Logging
- Emit debug logs in development builds.
- Keep user-facing message clean; avoid raw stack traces.
