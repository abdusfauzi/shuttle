# 07 - Navigation

## Menu Layout
- Dynamic host entries are injected before static items.
- Nested host groups map to nested `NSMenu` trees.
- Sort and separator tags are parsed from host names.

## Static Actions
Expected static menu actions include:
- Import config
- Export config
- Configure
- About
- Quit

## Behavior Guarantees
- Menu refreshes when config or ssh config mtime changes.
- Invalid config shows a disabled parse-error item instead of crashing.
