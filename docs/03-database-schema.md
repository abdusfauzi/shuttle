# 03 - Data Schema

Shuttle has no database. Persistence is file-based.

## Primary Data Sources
- User config JSON: `~/.shuttle.json`
- Optional custom config path marker: `~/.shuttle.path`
- SSH config files:
  - `~/.ssh/config`
  - `/etc/ssh_config`

## JSON Schema (Logical)
Top-level keys used today:
- `editor`: string
- `launch_at_login`: bool
- `terminal`: string
- `iTerm_version`: string (`stable` or `nightly`)
- `default_theme`: string
- `open_in`: string (`new`, `tab`, `current`, `virtual`)
- `show_ssh_config_hosts`: bool
- `ssh_config_ignore_hosts`: string[]
- `ssh_config_ignore_keywords`: string[]
- `hosts`: recursive node array

## Migration Schema Plan
- Introduce typed `Codable` models.
- Keep permissive fallback parsing to avoid breaking existing configs.
- Add optional schema validation warnings in debug builds.
