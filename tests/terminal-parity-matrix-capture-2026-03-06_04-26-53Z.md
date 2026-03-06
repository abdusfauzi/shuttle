# Terminal Parity Matrix Capture
Date (UTC): 2026-03-06_04-26-53Z
Host macOS: 26.3.1
Interactive mode: 0

1) Preflight checks
Checking embedded terminal script catalog and routing markers in AppServices.swift...
OK: parity resources and backend routing markers are present.
== Terminal Parity Probe ==
Date: 2026-03-06
macOS: 26.3.1

1) Preflight resource/routing check
Checking embedded terminal script catalog and routing markers in AppServices.swift...
OK: parity resources and backend routing markers are present.

2) Terminal app presence
- Terminal.app: installed | version=2.15 (466) | path=/System/Applications/Utilities/Terminal.app
- iTerm.app: installed | version=3.6.8 (3.6.8) | path=/Applications/iTerm.app
- Warp.app: installed | version=0.2026.03.04.08.20.02 (0.2026.03.04.08.20.02) | path=/Applications/Warp.app
- Ghostty.app: installed | version=1.2.3 (12214) | path=/Applications/Ghostty.app

Result: READY_FOR_MANUAL_MATRIX

2) Matrix execution
| Terminal | mode | status | result | notes |
|---|---|---|---|---|
| Terminal.app | new | pass | rc=0 |  |
| Terminal.app | tab | pass | rc=0 |  |
| Terminal.app | current | pass | rc=0 |  |
| Terminal.app | virtual | pass | rc=0 |  |
| iTerm (stable) | new | pass | rc=0 |  |
| iTerm (stable) | tab | pass | rc=0 |  |
| iTerm (stable) | current | pass | rc=0 |  |
| iTerm (stable) | virtual | pass | rc=0 |  |
| iTerm (nightly) | new | pass | rc=0 |  |
| iTerm (nightly) | tab | pass | rc=0 |  |
| iTerm (nightly) | current | pass | rc=0 |  |
| iTerm (nightly) | virtual | pass | rc=0 |  |
| Warp | new | pass | rc=0 |  |
| Warp | tab | pass | rc=0 |  |
| Warp | current | pass | rc=0 |  |
| Warp | virtual | pass | rc=0 |  |
| Ghostty | new | pass | rc=0 |  |
| Ghostty | tab | pass | rc=0 |  |
| Ghostty | current | pass | rc=0 |  |
| Ghostty | virtual | pass | rc=0 |  |

Summary: total=20 passed=20 failed=0
Result: PASS
Report: ./tests/terminal-parity-matrix-capture-2026-03-06_04-26-53Z.md
