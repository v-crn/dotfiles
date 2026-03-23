# Plan: Dotfiles Management with chezmoi (zsh)

**Date:** 2026-03-24
**Status:** Pending Approval

---

## Background

`/workspace/dotfiles` is an empty directory intended to manage personal dotfiles using chezmoi.
Starting with zsh-related dotfiles.

### Current State

- `~/.zshrc` exists with: history settings, compinit, emacs keybindings, aliases (eza, bat), PATH, mise, sheldon, starship
- No `.zshenv`, `.zprofile`, `.zlogin`, `.zlogout`
- `/workspace/dotfiles` is empty (not a git repository)

---

## Goals

- [ ] `.claude/CLAUDE.md` serves as project convention document
- [ ] `chezmoi managed` shows `.zshrc`
- [ ] `chezmoi diff` shows no diff (source matches target)
- [ ] `chezmoi apply -n` completes without error
- [ ] `bats tests/` passes all tests
- [ ] Initial commit created

---

## Repository Layout (Target)

```
/workspace/dotfiles/
├── .chezmoiroot          # content: "home"
├── .gitignore
├── .claude/
│   └── CLAUDE.md
├── home/                 # chezmoi source root
│   └── dot_zshrc         # -> ~/.zshrc
├── tests/
│   └── test_zsh.bats
└── docs/
    └── dev/
        └── plan/
            └── dotfiles-chezmoi-zsh.md  # this file
```

### chezmoi File Naming Conventions

| Prefix/Suffix | Meaning |
|---------------|---------|
| `dot_` prefix | Rename to `.` (e.g. `dot_zshrc` → `.zshrc`) |
| `private_` prefix | Set permissions to 0600 |
| `.tmpl` suffix | Process as Go template |
| `run_once_` prefix | Execute only once |

---

## Implementation Phases

### Phase 1: `.claude/CLAUDE.md` Creation

Create `/workspace/dotfiles/.claude/CLAUDE.md` with:
- Project overview
- Repository structure
- chezmoi commands reference
- Development guidelines
- Commit conventions

### Phase 2: chezmoi Initialization and zsh Dotfiles

| Step | Action |
|------|--------|
| 1 | `git init` in `/workspace/dotfiles` |
| 2 | Create `.gitignore` (exclude `.zsh_history`, etc.) |
| 3 | Create `.chezmoiroot` with content `home` |
| 4 | Create `home/` directory |
| 5 | Copy current `~/.zshrc` to `home/dot_zshrc` |
| 6 | Verify: `chezmoi diff` shows no diff |
| 7 | Verify: `chezmoi managed` lists `.zshrc` |

> **Note:** No templating needed initially. Consider `.tmpl` conversion when multi-environment support is required.

### Phase 3: Tests and Verification (bats-core)

Create `tests/test_zsh.bats` with:
- `dot_zshrc` file exists
- No syntax errors (`zsh -n`)
- Required sections present (History, Completion, PATH)
- `chezmoi apply -n` completes without error

---

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| `chezmoi apply` overwrites and breaks existing `.zshrc` | High | Always run `chezmoi diff` and `chezmoi apply -n` before applying |
| `.chezmoiroot` misconfiguration causes missing source | Medium | Verify immediately with `chezmoi managed` |
| bats not installed | Low | Assumed managed via mise; install if missing |

---

## Key chezmoi Commands

```bash
chezmoi init --source /workspace/dotfiles  # initialize with this repo
chezmoi apply                               # apply to home directory
chezmoi apply -n                            # dry-run
chezmoi diff                                # show diff
chezmoi add ~/.zshrc                        # add file to management
chezmoi edit ~/.zshrc                       # edit via chezmoi
chezmoi managed                             # list managed files
chezmoi cd                                  # cd to source directory
chezmoi data                                # show template variables
```
