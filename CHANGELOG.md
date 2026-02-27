# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Added support for selecting Warp and Ghostty as terminal backends.
- Added `virtual` open mode backed by `screen` for background command execution.
- Added French translations by @anivon.
- Added `[---]` separator syntax support in command names.
- Added `tests/regression_suite.sh` one-shot preflight/smoke/build runner with blocked-environment signaling (exit `2`).
- Added `tests/terminal_parity_probe.sh` to record installed terminal app versions for matrix evidence.
- Added `tests/terminal_parity_smoke.sh` AppleScript handler dispatch harness.
- Added `tests/terminal_parity_resource_check.sh` to validate required `.scpt` resources and backend routing markers.
- Added `tests/path_hygiene_check.sh` to prevent regressions from hardcoded workstation paths.
- Added `apple-scripts/compile-all.sh` canonical compiler entry point (project-root relative; exits `2` in headless environments).
- Added `docs/plans/terminal-parity-matrix.md` cross-terminal behavior matrix and execution runbook.
- Added `tests/compile_common_exit_code_check.sh` to validate AppleScript compiler failures propagate as non-zero exit codes.
- Added `tests/compile_all_policy_check.sh` to enforce default Warp legacy compile skip behavior.
- Added `tests/warp_legacy_compile_check.sh` to validate optional legacy Warp AppleScript compilation.
- Added proactive onboarding preflight checks for required setup (config readability, Accessibility, Automation to System Events).
- Added `tests/preflight_permissions_guard.sh`, `tests/preflight_alert_copy_check.sh`, and `tests/preflight_invocation_check.sh` for onboarding regression coverage.
- Added Ghostty onboarding fallback path for AppleEvents authorization failures and guard tests (`tests/ghostty_launch_policy_check.sh`, `tests/ghostty_automation_fallback_check.sh`).
- Added `tests/about_window_retention_check.sh` to prevent About popup action regressions.
- Added `tests/footprint_deployment_target_check.sh` and `tests/release_bundle_size_check.sh` to enforce deployment baseline and release footprint guardrails.

### Changed
- Migrated all app runtime code from Objective-C to Swift; `main.swift` is the active entrypoint.
- Extracted `ConfigService`, `SSHConfigParser`, `MenuBuilder`, and `TerminalRouter` from `AppDelegate.swift` into `Shuttle/AppServices.swift`; `AppDelegate.swift` is now orchestration-only.
- `TerminalRouter` now dispatches through isolated backend strategy types (`TerminalAppBackend`, `ITermBackend`, `WarpBackend`, `GhosttyBackend`) — one struct per terminal, no branching in the coordinator.
- Migrated launch-at-login to `LaunchAtLoginController.swift`; removed Objective-C implementation.
- Migrated `AboutWindowController` to `AboutWindowController.swift`.
- Updated `MainMenu.xib` metadata reference from legacy `AppDelegate.h` to `AppDelegate.swift`.
- Updated legacy Warp AppleScript helpers to compile cleanly with current AppleScript syntax.
- `apple-scripts/compile-all.sh` now skips deprecated Warp legacy helper compilation by default; opt-in via `INCLUDE_LEGACY_WARP_COMPILE=1`.
- AppleScript compile helper now correctly propagates non-zero compiler exit codes on failures.
- Ghostty command dispatch now avoids `open -na` instance fan-out and uses direct fallback execution when Automation permission is unavailable.
- URL launch detection is now strict-scheme only (`://`) to avoid misclassifying shell commands (for example `ssh ...`) as Finder URLs.
- About popup has refreshed spacing and now exposes separate links for original project and maintained fork.
- Minimum supported macOS target is now `13.0` to reduce release bundle footprint.
- @philippetev Changes to iTerm applescripts to fix issues with settings in iTerm's Preferences/General.
- @anivon localize "Error parsing config" message when JSON is invalid.
- @blackadmin version typos in about window.

### Removed
- Removed Objective-C runtime sources (`main.m`, `AppDelegate.m/.h`, `LaunchAtLoginController.m/.h`, `AboutWindowController.m/.h`).
- Removed Swift/Objective-C bridging header and prefix header from build settings.
- Removed stale duplicate `apple-scripts/iTermStable copy` directory.

### Pending
- The ability to add a second json.config file.
- Terminal parity matrix (M-004): live cell verification pending interactive macOS session with Automation/Accessibility permissions.

## [1.2.9] - 2016-10-18
### Added
- @pluwen added Chinese language translations #185

### Changed 
- All the documentation has been moved out of the readme.md and placed in the wiki.

### Fixed 
- Corrected by @pluwen icon changes changes #184
- Corrected by @bihicheng config file edits not working #199

## [1.2.8] - 2016-10-18
### Added
- Menus have been translated to Spanish
- Added a bash script to the default JSON file that allows writing a command to terminal without execution #200

### Fixed
- Fixed an issue that prevented character escapes #194
- Fixed an issue that prevented tabs from opening in terminal on macOS #198
- Fixed an issue where english was not the default language.

## [1.2.7] - 2016-07-24
### Added
- Now that iTerm stable is at version 3, the version 2 applescripts no longer apply to the stable branch. shuttle still supports iTerm 2.14. If you still want to use this legacy version you will have to change your iTerm_version setting to legacy. Valid settings are:

```"iTerm_version": "legacy",``` targeting iTerm 2.14

```"iTerm_version": "stable",``` targeting new versions of iTerm

```"iTerm_version": "nightly",``` targeting only the nightly build of iTerm

Please make sure to change your shuttle.JSON file accordingly. For more on this see #181

### Fixed 
- corrected by @mortonfox -- when iTerm startup preferences are set to "Don't Open Any Windows" nothing happens #175.
- corrected by @pluwen shuttle icon contains unwanted artifacts #141
- Fixed an issue where commas were not getting parsed #173

## [1.2.6] - 2016-02-24
### Added
- added by @keesfransen -- ssh config file parsing only keeps the first alias. This change keeps the menu clean as it only keeps the first argument to Host and will allow for hosts defined like:
```
Host prod/host host.prod
    HostName myserver.local
```
- Added the script files that compile the applescript files for inclusion in shuttle.app

### Fixed 
- corrected by @mortonfox -- when iTerm stable is running but no windows are open nothing happens.
- iTerm Stable and Terminal apple scripts were not correctly handling events where the app was open but no windows were open.
- Fixed an issue were iTerm Nightly applescripts would not open if a theme was not set.
- Fixed an issue with the URL detection. shuttle checks the command to see if its a URL then opens that URL in the default app.
Example:
```
"cmd": "cifs://myServer/c$"
```
Should open the above path in finder.

## [1.2.5] - 2015-11-05
### Added
- Added a new feature ```"open_in": "VALUE"``` is a global setting which sets how commands are open. Do they open in new tabs or new windows? This setting accepts the value of ```"tab"``` or ```"new"```
- Added a new feature ```"default_theme": "VALUE"``` is a global setting which sets the default theme for all terminal windows.
- Cleaned up the default JSON file and changed the names to reflect the action.
- Added alert boxes on errors for ```"iTerm_version": "VALUE"``` and ```"inTerminal": "VALUE"```

### Changed
- Changed the readme.md to reflect all options. Please see the new wiki it explains all of the settings.

## [1.2.4] - 2015-10-17
### Added
- If ```"title":"Terminal Title"``` is empty then the title becomes the same as the commands menu name.

### Fixed
- Fixed the icon it was not turning white.
- Fixed iTerm2 variable
- About window on top changes

## [1.2.3] - 2015-10-15
### Added
- Applescript Changes allow for iTerm Stable and Nightly support. Note that this only works with Nightly versions starting after 2.9.20150414
- Open a Command in a new window. In your JSON for the command add this directive:
```"inTerminal": "new",```
- Open a Command in the existing window. In your JSON for the command add this directive:
```"inTerminal": "current",```
- Add a Title to your window: In your JSON for the command add this directive:
```"title": "Dev Server - SSH"```
- Add a Theme to your window: In your JSON for the command add this directive:
```"theme": "Homebrew",```
- Change the Path to the JSON file. In your home directory create a file called ```~/.shuttle.path``` In this file is the path to the JSON settings. Mine currently reads ```/Users/thshdw/Desktop/shuttle.json```
- Change the default editor. In the JSON settings change ```“editor”: “default”``` will open the settings file from the Settings > edit menu in that editor. Set the editor to 'nano', 'vi', or any terminal based editor.
- Shuttle About Opens a GUI window that shows the version with a button to the home page.

## [1.2.2] - 2014-11-01
### Added
- Adds support for dark mode in Yosemite

## [1.2.0] - 2013-12-02
### Added
- Include option to show/hide servers from SSH config files
- Include option to ignore hosts based on name or keyword
- Ability to Import/Export settings file
- Support for multiple nested menus

### Fixed
- Remove status icon from status bar on quit

## [1.1.2] - 2013-07-23
### Fixed
- Fix issue with parsing the default JSON config file

## [1.1.1] - 2013-07-19
### Added
- cmd in .shuttle.json now supports URLs (http://, smb://, vnc://, etc.)
Opens in your OS default applications
- Added test configuration files

### Changed
- Create default config file on application load, instead of menu open

### Fixed
- Fix issue with iTerm running command in the previous tab's split, instead of the new tab.
- Escape double quote characters in cmd

## [1.1.0] - 2013-07-16
### Added
- Option to automatically launch at login
- In addition to the JSON config, also generate menu items from hosts in .ssh/config

## [1.0.1] - 2013-07-11
### Added
- OS X 10.7 support
- Change menu bar item to use an icon instead of "SSH".

## [1.0.0] - 2013-07-10
### Added
- Initial Release
