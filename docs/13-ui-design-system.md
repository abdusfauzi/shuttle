# 13 - UI Design System

## Current UI Surface
- Status bar icon (normal/alternate template variants).
- NSMenu host hierarchy.
- About window.
- Native NSAlert for error feedback.

## UX Constraints
- Keep interaction minimal and fast.
- Preserve menu readability for deep host trees.
- Keep error messages action-oriented.

## Migration Guidance
- Do not introduce visual regressions during Swift refactor.
- Keep resource naming stable until final cleanup.
