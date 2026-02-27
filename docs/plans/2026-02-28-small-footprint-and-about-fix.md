# Small Footprint and About Fix Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix About popup link buttons and reduce Shuttle distribution footprint by raising minimum macOS support to modern versions.

**Architecture:** First, fix the About window controller lifecycle bug so button actions reliably fire. Then raise deployment target to macOS 13+ and verify Swift runtime libraries are no longer bundled into `Shuttle.app`. Add regression scripts that enforce retention behavior and footprint constraints so future changes cannot silently bloat the app.

**Tech Stack:** Swift (AppKit), Xcode build settings (`MACOSX_DEPLOYMENT_TARGET`), shell regression scripts, Developer ID signed release build.

### Task 1: Fix About popup button actions (controller retention)

**Files:**
- Modify: `Shuttle/AppDelegate.swift`
- Test: `tests/about_window_retention_check.sh`

**Step 1: Write the failing test**

Create/update `tests/about_window_retention_check.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT_DIR/Shuttle/AppDelegate.swift"

if ! /usr/bin/grep -q "private var aboutWindowController: AboutWindowController?" "$SOURCE"; then
    echo "FAIL: About window controller is not retained." >&2
    exit 1
fi

if ! /usr/bin/grep -q "aboutWindowController = AboutWindowController" "$SOURCE"; then
    echo "FAIL: showAbout does not assign retained controller instance." >&2
    exit 1
fi

echo "OK: About window controller retention guard passed."
```

**Step 2: Run test to verify it fails**

Run: `chmod +x tests/about_window_retention_check.sh && ./tests/about_window_retention_check.sh`

Expected: `FAIL: About window controller is not retained.`

**Step 3: Write minimal implementation**

In `Shuttle/AppDelegate.swift`:
- Add property:

```swift
private var aboutWindowController: AboutWindowController?
```

- Update `showAbout(_:)` to keep a strong reference:

```swift
aboutWindowController = AboutWindowController(windowNibName: "AboutWindowController")
aboutWindowController?.showWindow(self)
aboutWindowController?.window?.makeKeyAndOrderFront(nil)
aboutWindowController?.window?.level = .floating
```

**Step 4: Run test to verify it passes**

Run: `./tests/about_window_retention_check.sh`

Expected: `OK: About window controller retention guard passed.`

**Step 5: Commit**

```bash
git add Shuttle/AppDelegate.swift tests/about_window_retention_check.sh
git commit -m "fix: retain about window controller so link buttons work"
```

### Task 2: Raise minimum macOS target for smaller Swift runtime footprint

**Files:**
- Modify: `Shuttle.xcodeproj/project.pbxproj`
- Modify: `Shuttle/Shuttle-Info.plist` (only if explicit value needed; keep variable if already present)
- Test: `tests/footprint_deployment_target_check.sh`

**Step 1: Write the failing test**

Create `tests/footprint_deployment_target_check.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

target="$(xcodebuild -project "$ROOT_DIR/Shuttle.xcodeproj" -scheme Shuttle -configuration Release -showBuildSettings | awk -F' = ' '/MACOSX_DEPLOYMENT_TARGET/ {print $2; exit}')"

if [[ "$target" != "13.0" ]]; then
    echo "FAIL: expected MACOSX_DEPLOYMENT_TARGET=13.0, got $target" >&2
    exit 1
fi

echo "OK: deployment target is pinned to macOS 13.0."
```

**Step 2: Run test to verify it fails**

Run: `chmod +x tests/footprint_deployment_target_check.sh && ./tests/footprint_deployment_target_check.sh`

Expected: `FAIL: expected MACOSX_DEPLOYMENT_TARGET=13.0, got 10.13`

**Step 3: Write minimal implementation**

In `Shuttle.xcodeproj/project.pbxproj`:
- Set target build configs `MACOSX_DEPLOYMENT_TARGET = 13.0;`
- Keep `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = NO;`

Do not add extra refactors; only deployment baseline change.

**Step 4: Run test to verify it passes**

Run: `./tests/footprint_deployment_target_check.sh`

Expected: `OK: deployment target is pinned to macOS 13.0.`

**Step 5: Commit**

```bash
git add Shuttle.xcodeproj/project.pbxproj tests/footprint_deployment_target_check.sh
git commit -m "build: raise minimum macOS target to 13 for smaller runtime footprint"
```

### Task 3: Enforce small bundle footprint in release artifact

**Files:**
- Create: `tests/release_bundle_size_check.sh`

**Step 1: Write the failing test**

Create `tests/release_bundle_size_check.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

APP_PATH="/tmp/ShuttleSignedBuild/Build/Products/Release/Shuttle.app"

[[ -d "$APP_PATH" ]] || { echo "FAIL: missing release app at $APP_PATH" >&2; exit 1; }

bundle_kb="$(du -sk "$APP_PATH" | awk '{print $1}')"

if [[ -d "$APP_PATH/Contents/Frameworks" ]]; then
    framework_count="$(ls -1 "$APP_PATH/Contents/Frameworks" | wc -l | tr -d ' ')"
else
    framework_count="0"
fi

if [[ "$framework_count" -ne 0 ]]; then
    echo "FAIL: expected 0 embedded Swift frameworks, found $framework_count" >&2
    exit 1
fi

if [[ "$bundle_kb" -gt 4096 ]]; then
    echo "FAIL: expected bundle <= 4096 KB, got ${bundle_kb} KB" >&2
    exit 1
fi

echo "OK: release bundle footprint check passed (${bundle_kb} KB, frameworks=$framework_count)."
```

**Step 2: Run test to verify it fails**

Run:
- `chmod +x tests/release_bundle_size_check.sh`
- `xcodebuild -project Shuttle.xcodeproj -scheme Shuttle -configuration Release -sdk macosx -derivedDataPath /tmp/ShuttleSignedBuild DEVELOPMENT_TEAM=6G94876K55 CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="Developer ID Application: MZR Global Sdn Bhd (6G94876K55)" build`
- `./tests/release_bundle_size_check.sh`

Expected: FAIL before deployment target change is complete, due to embedded frameworks and/or size.

**Step 3: Write minimal implementation**

No new production code; implementation is completion of Task 2 build setting change.

**Step 4: Run test to verify it passes**

Run same 3 commands from Step 2.

Expected: `OK: release bundle footprint check passed ...`

**Step 5: Commit**

```bash
git add tests/release_bundle_size_check.sh
git commit -m "test: enforce release bundle footprint and no embedded swift runtimes"
```

### Task 4: Update release docs and changelog for new support baseline

**Files:**
- Modify: `docs/15-deployment-guide.md`
- Modify: `CHANGELOG.md`

**Step 1: Add deployment note**

Update deployment guide with:
- Minimum supported macOS is now 13.0.
- Footprint expectation and `tests/release_bundle_size_check.sh` gate.

**Step 2: Update changelog**

In `CHANGELOG.md` Unreleased:
- Added: release footprint check script.
- Changed: minimum macOS support raised to 13.0 for smaller app bundle.

**Step 3: Verification**

Run:
- `./tests/about_window_retention_check.sh`
- `./tests/footprint_deployment_target_check.sh`
- `./tests/release_bundle_size_check.sh`
- `./tests/regression_suite.sh --with-compile`

Expected: all pass; regression suite returns `REGRESSION_PASS`.

**Step 4: Commit**

```bash
git add docs/15-deployment-guide.md CHANGELOG.md
git commit -m "docs: document macOS 13 baseline and footprint gates"
```
