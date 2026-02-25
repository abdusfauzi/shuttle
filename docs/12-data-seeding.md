# 12 - Data Seeding

## Purpose
Provide reproducible config fixtures for development and test verification.

## Fixture Sources
- `Shuttle/shuttle.default.json`
- `tests/` sample config files

## Suggested Fixture Set
- Minimal single-host config.
- Deeply nested group config.
- Mixed terminal targets and `inTerminal` modes.
- Invalid config for parser/error validation.

## Seeding Workflow
- Copy a fixture into `~/.shuttle.json`.
- Restart Shuttle or reopen menu to reload.
- Validate expected menu structure and command dispatch.
