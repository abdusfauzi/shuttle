# 11 - Environment Config

## Build Requirements
- Xcode with macOS SDK.
- Deployment target: macOS 10.13+.
- Project: `Shuttle.xcodeproj`, scheme `Shuttle`.

## Local Build Example
- `xcodebuild -project Shuttle.xcodeproj -scheme Shuttle -configuration Debug -sdk macosx -derivedDataPath /tmp/ShuttleDerivedData build`

## AppleScript Resource Build
- Canonical compile entrypoint: `./apple-scripts/compile-all.sh`
- Script helpers now resolve paths relative to the project root; no user-specific absolute paths are required.

## Runtime File Paths
- Config path marker: `~/.shuttle.path`
- Default config: `~/.shuttle.json`
- SSH config: `~/.ssh/config`, `/etc/ssh_config`

## Notes
- In restricted environments, default Xcode derived data paths may be blocked; use `-derivedDataPath` override.
- `./apple-scripts/compile-all.sh` requires interactive macOS AppleScript services and returns exit code `2` when run in sandbox/headless sessions.
