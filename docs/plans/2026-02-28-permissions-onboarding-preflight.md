# Permissions Onboarding Preflight Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Show a startup preflight card that guides users to grant required permissions (Accessibility + Automation) and confirms config readability before they try any SSH shortcut.

**Architecture:** Add a small preflight service that performs three checks (config readable, Accessibility trusted, Automation to System Events). Integrate it at app startup and before command execution, and present a single actionable NSAlert-based onboarding card with direct links to System Settings panes. Keep behavior minimal and reversible: no wizard, no extra windows, no unrelated diagnostics.

**Tech Stack:** Swift (AppKit), NSAlert, AXIsProcessTrustedWithOptions, NSAppleScript probe, existing AppDelegate/ConfigService/TerminalRouter.

### Task 1: Add preflight check model + service

**Files:**
- Create: `Shuttle/OnboardingPreflight.swift`
- Modify: `Shuttle.xcodeproj/project.pbxproj`
- Test: `tests/preflight_permissions_guard.sh`

**Step 1: Write the failing test**

Create `tests/preflight_permissions_guard.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/Shuttle/OnboardingPreflight.swift"

[[ -f "$SOURCE_FILE" ]] || { echo "FAIL: missing OnboardingPreflight.swift" >&2; exit 1; }
grep -q "AXIsProcessTrustedWithOptions" "$SOURCE_FILE" || { echo "FAIL: no Accessibility check" >&2; exit 1; }
grep -q "System Events" "$SOURCE_FILE" || { echo "FAIL: no AppleEvents probe" >&2; exit 1; }
grep -q "configReadable" "$SOURCE_FILE" || { echo "FAIL: no config readability check" >&2; exit 1; }
echo "OK: preflight service baseline present."
```

**Step 2: Run test to verify it fails**

Run: `chmod +x tests/preflight_permissions_guard.sh && ./tests/preflight_permissions_guard.sh`

Expected: `FAIL: missing OnboardingPreflight.swift`

**Step 3: Write minimal implementation**

Create `Shuttle/OnboardingPreflight.swift` with:

```swift
import Cocoa
import ApplicationServices

struct PreflightStatus {
    let configReadable: Bool
    let accessibilityGranted: Bool
    let automationGranted: Bool
    var isReady: Bool { configReadable && accessibilityGranted && automationGranted }
}

final class OnboardingPreflight {
    func evaluate(configPath: String) -> PreflightStatus {
        let configReadable = FileManager.default.isReadableFile(atPath: configPath)
        let accessibilityGranted = AXIsProcessTrusted()
        let automationGranted = probeAutomationToSystemEvents()
        return PreflightStatus(
            configReadable: configReadable,
            accessibilityGranted: accessibilityGranted,
            automationGranted: automationGranted
        )
    }

    private func probeAutomationToSystemEvents() -> Bool {
        let script = NSAppleScript(source: "tell application \"System Events\" to name of first process")
        var error: NSDictionary?
        _ = script?.executeAndReturnError(&error)
        return error == nil
    }
}
```

Add new file to Xcode project build phase.

**Step 4: Run test to verify it passes**

Run: `./tests/preflight_permissions_guard.sh`

Expected: `OK: preflight service baseline present.`

**Step 5: Commit**

```bash
git add tests/preflight_permissions_guard.sh Shuttle/OnboardingPreflight.swift Shuttle.xcodeproj/project.pbxproj
git commit -m "feat: add onboarding preflight permission service"
```

### Task 2: Add onboarding card UI with actionable remediation

**Files:**
- Modify: `Shuttle/AppDelegate.swift`
- Modify: `Shuttle/en.lproj/Localizable.strings`
- Modify: `Shuttle/es.lproj/Localizable.strings`
- Modify: `Shuttle/fr.lproj/Localizable.strings`
- Modify: `Shuttle/zh-Hans.lproj/Localizable.strings`
- Test: `tests/preflight_alert_copy_check.sh`

**Step 1: Write the failing test**

Create `tests/preflight_alert_copy_check.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT_DIR/Shuttle/AppDelegate.swift"

grep -q "showPreflightOnboardingIfNeeded" "$SOURCE" || { echo "FAIL: onboarding entrypoint missing" >&2; exit 1; }
grep -q "Open Privacy Settings" "$SOURCE" || { echo "FAIL: missing privacy settings action" >&2; exit 1; }
grep -q "Open Config" "$SOURCE" || { echo "FAIL: missing open config action" >&2; exit 1; }
echo "OK: onboarding alert wiring present."
```

**Step 2: Run test to verify it fails**

Run: `chmod +x tests/preflight_alert_copy_check.sh && ./tests/preflight_alert_copy_check.sh`

Expected: `FAIL: onboarding entrypoint missing`

**Step 3: Write minimal implementation**

In `Shuttle/AppDelegate.swift`:
- Add property: `private let onboardingPreflight = OnboardingPreflight()`
- Add method:

```swift
private func showPreflightOnboardingIfNeeded() {
    let status = onboardingPreflight.evaluate(configPath: shuttleConfigFile)
    guard !status.isReady else { return }

    let alert = NSAlert()
    alert.messageText = NSLocalizedString("Shuttle setup required", comment: "")
    alert.informativeText = preflightMessage(status)
    alert.addButton(withTitle: NSLocalizedString("Open Privacy Settings", comment: ""))
    alert.addButton(withTitle: NSLocalizedString("Open Config", comment: ""))
    alert.addButton(withTitle: NSLocalizedString("Continue", comment: ""))

    switch alert.runModal() {
    case .alertFirstButtonReturn: openPrivacySettings()
    case .alertSecondButtonReturn: configure(nil)
    default: break
    }
}
```

- Implement:
  - `private func openPrivacySettings()` opens `x-apple.systempreferences:com.apple.preference.security?Privacy`
  - `private func preflightMessage(_ status: PreflightStatus) -> String` listing only missing requirements.

Add localization keys for:
- `Shuttle setup required`
- `Open Privacy Settings`
- `Open Config`
- `Continue`
- `Accessibility permission is required.`
- `Automation permission is required (System Events).`
- `Config file is not readable.`

**Step 4: Run test to verify it passes**

Run: `./tests/preflight_alert_copy_check.sh`

Expected: `OK: onboarding alert wiring present.`

**Step 5: Commit**

```bash
git add Shuttle/AppDelegate.swift Shuttle/*/Localizable.strings tests/preflight_alert_copy_check.sh
git commit -m "feat: add startup onboarding card for required permissions"
```

### Task 3: Trigger onboarding proactively (startup + pre-command gate)

**Files:**
- Modify: `Shuttle/AppDelegate.swift`
- Test: `tests/preflight_invocation_check.sh`

**Step 1: Write the failing test**

Create `tests/preflight_invocation_check.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT_DIR/Shuttle/AppDelegate.swift"

grep -q "showPreflightOnboardingIfNeeded()" "$SOURCE" || { echo "FAIL: preflight is never invoked" >&2; exit 1; }
grep -q "@IBAction func openHost" "$SOURCE" || { echo "FAIL: openHost action missing" >&2; exit 1; }
echo "OK: preflight invocation hooks present."
```

**Step 2: Run test to verify it fails**

Run: `chmod +x tests/preflight_invocation_check.sh && ./tests/preflight_invocation_check.sh`

Expected: `FAIL: preflight is never invoked`

**Step 3: Write minimal implementation**

In `Shuttle/AppDelegate.swift`:
- Call `showPreflightOnboardingIfNeeded()` at end of `awakeFromNib()`.
- In `openHost(_:)`, run preflight before dispatch:

```swift
let status = onboardingPreflight.evaluate(configPath: shuttleConfigFile)
if !status.isReady {
    showPreflightOnboardingIfNeeded()
    return
}
```

This ensures users are guided before command execution.

**Step 4: Run test to verify it passes**

Run: `./tests/preflight_invocation_check.sh`

Expected: `OK: preflight invocation hooks present.`

**Step 5: Commit**

```bash
git add Shuttle/AppDelegate.swift tests/preflight_invocation_check.sh
git commit -m "feat: gate shortcut execution behind preflight readiness"
```

### Task 4: End-to-end verification and docs update

**Files:**
- Modify: `docs/15-deployment-guide.md`
- Modify: `CHANGELOG.md`

**Step 1: Add verification checklist entry**

Update deployment guide with onboarding verification:
- Fresh install run from `/Applications/Shuttle.app`
- On first launch, preflight card appears when missing permissions
- Buttons open Privacy and Config
- After granting permissions, shortcut runs without onboarding block

**Step 2: Build verification**

Run: `xcodebuild -project Shuttle.xcodeproj -scheme Shuttle -configuration Release -sdk macosx -derivedDataPath /tmp/ShuttleSignedBuild build`

Expected: `** BUILD SUCCEEDED **`

**Step 3: Regression verification**

Run:
- `./tests/preflight_permissions_guard.sh`
- `./tests/preflight_alert_copy_check.sh`
- `./tests/preflight_invocation_check.sh`
- `./tests/ghostty_launch_policy_check.sh`
- `./tests/ghostty_automation_fallback_check.sh`

Expected: all return `OK`.

**Step 4: Update changelog**

Add Unreleased bullet: onboarding preflight with proactive permission guidance.

**Step 5: Commit**

```bash
git add docs/15-deployment-guide.md CHANGELOG.md
git commit -m "docs: add onboarding preflight verification and release notes"
```
