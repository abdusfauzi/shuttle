# 20 - Accessibility

## Current State
- Shuttle UI is primarily NSStatusItem + NSMenu based.
- Keyboard navigation is handled by native macOS menu behavior.

## Accessibility Requirements
- Menu item titles must be descriptive and unique enough for navigation.
- Alerts should provide clear, concise text for assistive technologies.
- Avoid workflows that require precise pointer actions only.

## Validation Checklist
- Navigate menu entirely by keyboard.
- Confirm alert dialogs are readable by VoiceOver.
- Validate icon/template contrast behavior in light/dark menu bar contexts.
