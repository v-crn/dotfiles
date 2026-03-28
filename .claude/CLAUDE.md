# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Project Overview

- **Target environment:** WSL2 (Linux) / macOS / Linux Distro / zsh
- **Dotfile Manager:** chezmoi (source directory layout with `.chezmoiroot`)
- **Shell:** zsh with sheldon (plugins), starship (prompt), mise (runtime manager)

> This repository is designed to grow incrementally — zsh, git, vim, SSH, and other tool configs
> will be added over time.

## Repository Structure

```text
dotfiles/
├── .chezmoiroot                          # Points chezmoi source root to "home/"
├── .gitignore
├── .claude/
│   └── CLAUDE.md                         # This file
├── home/                                 # chezmoi source root
│   ├── dot_zshenv.tmpl                   # -> ~/.zshenv  (all shells: XDG, EDITOR, LANG)
│   ├── dot_zprofile.tmpl                 # -> ~/.zprofile  (login shells: PATH, Homebrew)
│   ├── dot_zshrc.tmpl                    # -> ~/.zshrc  (interactive shells: sources config/)
│   ├── dot_config/
│   │   ├── chezmoi/
│   │   │   └── private_chezmoi.toml.tmpl # -> ~/.config/chezmoi/chezmoi.toml (0600)
│   │   ├── sheldon/
│   │   │   └── plugins.toml              # -> ~/.config/sheldon/plugins.toml
│   │   ├── zsh/                          # Glob-loaded by ~/.zshrc (alphabetical order)
│   │   │   ├── 50_sheldon.zsh            # -> ~/.config/zsh/50_sheldon.zsh  (loads before completion)
│   │   │   ├── 60_completion.zsh         # -> ~/.config/zsh/60_completion.zsh (compinit + fzf-tab)
│   │   │   ├── aliases.zsh               # -> ~/.config/zsh/aliases.zsh
│   │   │   ├── dart.zsh                  # -> ~/.config/zsh/dart.zsh
│   │   │   ├── docker-compose.zsh        # -> ~/.config/zsh/docker-compose.zsh
│   │   │   ├── dotnet.zsh                # -> ~/.config/zsh/dotnet.zsh
│   │   │   ├── flutter.zsh               # -> ~/.config/zsh/flutter.zsh
│   │   │   ├── git.zsh                   # -> ~/.config/zsh/git.zsh
│   │   │   ├── golang.zsh                # -> ~/.config/zsh/golang.zsh
│   │   │   ├── google-cloud-sdk.zsh      # -> ~/.config/zsh/google-cloud-sdk.zsh
│   │   │   ├── history.zsh               # -> ~/.config/zsh/history.zsh
│   │   │   ├── homebrew.zsh              # -> ~/.config/zsh/homebrew.zsh
│   │   │   ├── keybindings.zsh           # -> ~/.config/zsh/keybindings.zsh
│   │   │   ├── mise.zsh                  # -> ~/.config/zsh/mise.zsh
│   │   │   ├── nvcc.zsh                  # -> ~/.config/zsh/nvcc.zsh
│   │   │   ├── nvidia-smi.zsh            # -> ~/.config/zsh/nvidia-smi.zsh
│   │   │   ├── nvim.zsh                  # -> ~/.config/zsh/nvim.zsh
│   │   │   ├── rust.zsh                  # -> ~/.config/zsh/rust.zsh
│   │   │   ├── starship.zsh              # -> ~/.config/zsh/starship.zsh
│   │   │   └── xclip.zsh                 # -> ~/.config/zsh/xclip.zsh
│   │   └── starship.toml                 # -> ~/.config/starship.toml
│   └── run_once_set-zsh-config-permissions.sh  # chmod 700 ~/.config/zsh
├── tests/
│   └── test_zsh.bats                     # Shell tests (bats-core)
└── docs/
    ├── setup.md                          # Setup guide (new machine, troubleshooting)
    ├── zsh.md                            # zsh config structure and load order
    ├── tools/                            # Per-tool documentation
    │   ├── sheldon.md
    │   ├── starship.md
    │   ├── mise.md
    │   ├── eza.md
    │   ├── bat.md
    │   └── fzf.md
    ├── plan/                             # Implementation plans (YYYY-MM-DD-<topic>.md)
    ├── spec/                             # Specifications
    └── dev/
        └── plan/                         # Legacy plans (migrating to docs/plan/)
```

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

### Testing

Run all tests:

```bash
bats tests/
```

Tests are written with [bats-core](https://github.com/bats-core/bats-core).

## Commit Conventions

```text
feat:     add new dotfile
fix:      fix configuration
refactor: restructure config
docs:     update documentation
test:     add/update tests
chore:    tooling, CI changes
```
