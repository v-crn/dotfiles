# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Project Overview

- **Target environment:** WSL2 (Linux) / macOS / Linux Distro / zsh
- **Tool:** chezmoi (source directory layout with `.chezmoiroot`)
- **Shell:** zsh with sheldon (plugins), starship (prompt), mise (runtime manager)

## Repository Structure

```
dotfiles/
├── .chezmoiroot          # Points chezmoi source root to "home/"
├── .gitignore
├── .claude/
│   └── CLAUDE.md         # This file
├── home/                 # chezmoi source root
│   └── dot_zshrc         # -> ~/.zshrc
├── tests/
│   └── test_zsh.bats     # Shell tests (bats-core)
└── docs/
    └── dev/
        └── plan/         # Implementation plans
```

## chezmoi File Naming Conventions

| Prefix/Suffix     | Effect                                      |
|-------------------|---------------------------------------------|
| `dot_` prefix     | Rename to `.` (e.g. `dot_zshrc` → `.zshrc`) |
| `private_` prefix | Set permissions to 0600                     |
| `.tmpl` suffix    | Process as Go template                      |
| `run_once_` prefix | Execute only once                          |

## Setup

```bash
# Clone and initialize
git clone <repo-url> ~/dotfiles
chezmoi init --source ~/dotfiles

# Preview before applying
chezmoi diff

# Apply
chezmoi apply
```

## Common Commands

```bash
chezmoi add ~/.zshrc        # Add file to management
chezmoi edit ~/.zshrc       # Edit managed file
chezmoi diff                # Show diff between source and target
chezmoi apply -n            # Dry-run (preview only)
chezmoi apply               # Apply to home directory
chezmoi managed             # List all managed files
chezmoi cd                  # cd to source directory
chezmoi data                # Show template variables
```

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

### Testing

Run all tests:
```bash
bats tests/
```

Tests are written with [bats-core](https://github.com/bats-core/bats-core).

## Commit Conventions

```
feat:     add new dotfile
fix:      fix configuration
refactor: restructure config
docs:     update documentation
test:     add/update tests
chore:    tooling, CI changes
```
