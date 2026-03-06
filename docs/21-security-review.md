# 21 - Security Review

## Scope
This review covers input handling, command execution paths, and launch-time configuration surfaces in the Swift migration after full terminal backend isolation (Terminal.app, iTerm, Warp, Ghostty).

## Threat Model
- **Config data** from `~/.shuttle.json`, `~/.shuttle.path`, `~/.ssh/config`, and environment variables are user-controlled (or user-editable).
- **Commands** are executed through terminal launch strategies that can invoke AppleScript, `open`, and shell entry points.
- **Automation** paths depend on Apple Events and Accessibility permissions and can fail in restricted environments.

## Findings
1. **Command string handling risk (medium)**
   - Inputs from JSON and ssh-config host aliases entered execution paths.
   - Without additional quoting controls, shell metacharacters in hosts or editor commands could alter intended terminal behavior.
   - Status: **Mitigated** with centralized command validation and host quoting controls.

2. **Open-mode normalization risk (low)**
   - Variants like `tab ` or mixed-case values could bypass strictness checks.
   - Status: **Mitigated** through case/whitespace normalization and allow-list validation at dispatch.

3. **URL dispatch confusion (low)**
   - Non-URL command text should not be treated as URLs.
   - Status: **Mitigated** by scheme allow-list checks before URL launch.

4. **Legacy launch-at-login API risk (medium/compatibility)**
   - `LSSharedFileList*` remains for macOS <13.0 compatibility.
   - Status: **Contained**; guarded by 10.13 baseline and isolated behind `LegacyLoginItemStore` in `LaunchAtLoginController.swift`.

## Controls Implemented
- `SecurityPolicies`
  - `sanitizeOpenMode(_:)` now enforces `new|current|tab|virtual`.
  - `isSafeCommand(_:)` blocks control characters and empty/oversized commands.
  - `shellSingleQuote(_:)` and `isSafeHostAlias(_:)` added for command-argument hardening.
- `ConfigService.loadConfigSnapshot`
  - Config path and JSON file size/presence checks before parsing.
  - Normalized `open_in` assignment through allow-list sanitizer.
- `ConfigService.mergeSSHHosts`
  - Host names from SSH config now build commands as shell-safe quoted arguments.
- `TerminalRouter.resolvedOpenMode`
  - Menu-embedded `inTerminal` value now normalized and validated before dispatch.
- `AppDelegate.configure`
  - Rejects unsafe editor command prefixes and uses shell-quoted config path argument.

## Verification
- `xcodebuild -project Shuttle.xcodeproj -scheme Shuttle -configuration Debug -sdk macosx -derivedDataPath /tmp/ShuttleDerivedData build`
- `./tests/regression_suite.sh`
- `./tests/path_hygiene_check.sh`
- `./tests/terminal_parity_smoke.sh`

## Residual Risks
- AppleScript UI automation remains the least robust path for Warp/Ghostty and depends on user-granted permissions.
- Legacy Launch-at-login implementation is kept for macOS 10.13 compatibility and must remain isolated from command execution logic.
- Deprecated login-item APIs are confined to `LegacyLoginItemStore`; any future compatibility change should replace that helper as a single unit.
- User-typed JSON still influences which actions are exposed; accidental misconfiguration can still occur and should be treated as a configuration risk with UI guardrails.
- Runtime parity now depends on embedded template selectors in `TerminalScriptCatalog`; missing or malformed templates should be treated as an integrity defect via `terminal_parity_resource_check.sh`.

## Residual Action Items
- Keep `tests/security_review_check.sh` as a required step in regression and release validation.
- Extend regression suite with a unit-test style validation script for `TerminalLaunchRequest`, host alias escaping, and open-mode normalization.
