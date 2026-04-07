# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Project Overview

- **Target environment:** WSL2 (Linux) / macOS / Linux Distro / zsh
- **Dotfile Manager:** chezmoi (source directory layout with `.chezmoiroot`)
- **Shell:** zsh with sheldon (plugins), starship (prompt), mise (runtime manager)

> This repository is designed to grow incrementally — zsh, git, vim, SSH, and other tool configs
> will be added over time.

## chezmoi File Naming Conventions

| Prefix/Suffix     | Effect                                      |
| --- | --- | --- |
| `dot_` prefix     | Rename to `.` (e.g. `dot_zshrc` → `.zshrc`) |
| `private_` prefix | Set permissions to 0600                     |
| `.tmpl` suffix    | Process as Go template                      |
| `run_once_` prefix | Execute only once                          |

## Setup

```bash
# Clone and initialize
git clone https://github.com/v-crn/dotfiles
cd dotfiles

chezmoi init --source .

# Preview before applying
chezmoi diff --source .

# Apply
chezmoi apply --source .
```

## Common Commands

### make commands

@Makefile

### chezmoi commands

```bash
chezmoi add ~/.zshrc --source .    # Add file to management
chezmoi edit ~/.zshrc --source .   # Edit managed file
chezmoi diff --source .            # Show diff between source and target
chezmoi apply -n --source .        # Dry-run (preview only)
chezmoi apply --source .           # Apply to home directory
chezmoi managed --source .         # List all managed files
chezmoi cd --source .              # cd to source directory
chezmoi data --source .            # Show template variables
```

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

### Adding New Dotfiles

```bash
chezmoi add ~/.<filename>
# Then commit the new file in home/
```

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
