# 13 - UI Design System

## Current UI Surface
- Status bar icon (normal/alternate template variants).
- NSMenu host hierarchy.
- Centered Settings window for permissions, config location, and About metadata.
- Native NSAlert for error feedback.

## UX Constraints
- Keep interaction minimal and fast.
- Preserve menu readability for deep host trees.
- Keep setup guidance inline in Settings rather than blocking menu use with modal onboarding alerts.

## Migration Guidance
- Do not introduce visual regressions during Swift refactor.
- Keep resource naming stable until final cleanup.
