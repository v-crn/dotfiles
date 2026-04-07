# Coding Agents Rules

## Project Overview

Read @README.md

## chezmoi Conventions

Read `docs/tools/chezmoi.md` if you need further details about chezmoi.

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

### Workflow (TDD-first)

1. **Requirement Confirmation**: Clarify requirements with the user and confirm the implementation plan.
2. **Red (Write a failing test)**: Create or update a test file in `tests/` (using `bats`) that fails without the new change.
3. **Green (Implement)**: Edit the source files (e.g., in `home/`) to make the test pass.
4. **Refactor**: Clean up the code while ensuring tests remain green.
5. **Validation & Preview**:
    - Run all tests: `make test`
    - Preview changes: `make diff`
6. **User Confirmation**: Show the test results and diff to the user, and **ask for confirmation** before proceeding to apply or commit.
7. **Apply & Commit**:
    - Apply changes: `make apply` (if requested)
    - Commit changes following the conventions below.

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
