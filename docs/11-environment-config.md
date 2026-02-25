# 11 - Environment Config

## Build Requirements
- Xcode with macOS SDK.
- Deployment target: macOS 10.13+.
- Project: `Shuttle.xcodeproj`, scheme `Shuttle`.

## Local Build Example
- `xcodebuild -project Shuttle.xcodeproj -scheme Shuttle -configuration Debug -sdk macosx -derivedDataPath /tmp/ShuttleDerivedData build`

## Runtime File Paths
- Config path marker: `~/.shuttle.path`
- Default config: `~/.shuttle.json`
- SSH config: `~/.ssh/config`, `/etc/ssh_config`

## Notes
- In restricted environments, default Xcode derived data paths may be blocked; use `-derivedDataPath` override.
