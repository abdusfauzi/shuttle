# 04 - API Specifications

This app exposes no HTTP API. "API" here means internal module contracts.

## Proposed Internal APIs
- `ConfigServiceProtocol`
  - `loadConfig() throws -> ShuttleConfig`
- `SSHHostProviderProtocol`
  - `loadHosts() throws -> [HostDefinition]`
- `MenuBuilding`
  - `buildMenu(from hosts: [HostDefinition]) -> NSMenu`
- `TerminalRouting`
  - `open(command: String, target: TerminalTarget, mode: TerminalWindowMode, context: TerminalContext) throws`
- `ScriptRunning`
  - `run(script: ScriptAsset, handler: String, args: [String]) throws`

## Error Surface
All internal APIs should throw typed `ShuttleError` values mapped to user dialogs by `ErrorPresenter`.
