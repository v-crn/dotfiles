# Coding Agents Rules (Dotfiles)

## Project Overview

Read @README.md

## chezmoi Conventions

[docs/tools/chezmoi.md](docs/tools/chezmoi.md) 参照

## Design Principles

- **Portability** — Support Linux and macOS. Use chezmoi templates (`{{ .chezmoi.os }}`) for platform differences.
- **Graceful degradation** — Guard every optional tool with `command -v`; missing tools must never break the shell.
- **Extensibility** — Each tool gets its own file(s) under `home/` and a corresponding test in `tests/`.
- **Maintainability** — Comment non-obvious settings. Keep templates readable. Tests must stay green.
- **Generality** — Machine-specific values go in `~/.config/chezmoi/chezmoi.toml`, not hardcoded in source.

## Documentation Policy

- Documents under `docs/` are preferably written in Japanese
- Implementation plans go in `docs/plan/` as Markdown files (`YYYY-MM-DD-<topic>.md`)
- Specifications go in `docs/spec/` as Markdown files

## Development Guidelines

### Workflow

1. Edit in source: `chezmoi edit ~/.zshrc` or edit `home/dot_zshrc` directly
2. Preview: `chezmoi diff`
3. Apply: `chezmoi apply`
4. Test: `bats tests/`
5. Commit

### Templates

Use `.tmpl` suffix when a config needs to differ between environments (e.g., work vs. personal).
Template variables are defined in `~/.config/chezmoi/chezmoi.toml`.

## Commit Conventions

```text
feat:     add new dotfile
fix:      fix configuration
refactor: restructure config
docs:     update documentation
test:     add/update tests
chore:    tooling, CI changes
```
