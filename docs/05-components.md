# 05 - Components

## Existing Components
- Status item and menu lifecycle.
- JSON and SSH config parsing.
- Menu tree construction.
- Host/command execution router.
- AppleScript execution engine.
- Import/export/configure/about/quit actions.

## Component Refactor Targets
- Split AppDelegate into composable services.
- Remove NSDictionary/NSMutableArray usage from core logic.
- Convert stringly-typed represented objects into typed models.
- Move terminal-specific logic from conditionals into backend implementations.

## Definition of Done Per Component
- Unit tests for nominal and failure paths.
- No Objective-C runtime calls in component internals.
- Explicit interfaces, no hidden global state.
