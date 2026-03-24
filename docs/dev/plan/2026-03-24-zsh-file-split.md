# Plan: zsh Config File Split

**Date:** 2026-03-24
**Status:** Draft
**Scope:** Split monolithic `dot_zshrc.tmpl` into role-based files following zsh startup order,
with modular per-tool files under `~/.config/zsh/`.

---

## Background

The current `home/dot_zshrc.tmpl` mixes history, completion, keybindings, aliases, PATH, and
tool activations into one file. A role-based split improves portability, debuggability, and
maintainability — and aligns with zsh startup semantics.

A security review was conducted on the proposed design before implementation. Several HIGH and
MEDIUM findings shaped the final plan (see Security Decisions below).

---

## zsh Startup File Roles

| File | Loaded when | Purpose |
|------|-------------|---------|
| `~/.zshenv` | Every shell (login, interactive, script, cron, SSH) | Essential env vars only |
| `~/.zprofile` | Login shells only (before `.zshrc`) | Login-time setup (Homebrew PATH) |
| `~/.zshrc` | Interactive shells only | Sources modular config files |
| `~/.zlogin` | Login shells (after `.zshrc`) | Not used — unnecessary for this setup |

---

## Target Structure

```
home/
├── dot_zshenv.tmpl                     → ~/.zshenv
├── dot_zprofile.tmpl                   → ~/.zprofile
├── dot_zshrc.tmpl                      → ~/.zshrc
├── dot_config/
│   └── zsh/
│       ├── history.zsh                 → ~/.config/zsh/history.zsh
│       ├── completion.zsh              → ~/.config/zsh/completion.zsh
│       ├── keybindings.zsh             → ~/.config/zsh/keybindings.zsh
│       ├── aliases.zsh                 → ~/.config/zsh/aliases.zsh
│       ├── mise.zsh                    → ~/.config/zsh/mise.zsh
│       ├── sheldon.zsh                 → ~/.config/zsh/sheldon.zsh
│       └── starship.zsh               → ~/.config/zsh/starship.zsh
└── private_dot_config/
    └── chezmoi/
        └── chezmoi.toml.tmpl           → ~/.config/chezmoi/chezmoi.toml
```

---

## File Contents

### `dot_zshenv.tmpl` — Universal environment variables

Sourced for ALL shells. Must be fast, minimal, and free of side effects.

```zsh
# SECURITY: Sourced for ALL shells (interactive, non-interactive, cron, SSH, scripts).
# PROHIBITED: eval, echo/printf output, tool activations (mise/sheldon/starship),
#             umask changes, CDPATH, anything that produces stdout.
# Only set variables that every shell context genuinely needs.

# ── XDG Base Directory ────────────────────────────────────────────────────────
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# ── Core environment ──────────────────────────────────────────────────────────
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-$EDITOR}"
export LANG="${LANG:-en_US.UTF-8}"
```

**Prohibited content (enforced by bats test):**
- `eval`
- `echo` / `printf` (breaks SSH scp/rsync/sftp)
- Tool activations (`mise`, `sheldon`, `starship`)
- PATH modifications (→ goes in `.zprofile`)

### `dot_zprofile.tmpl` — Login shell setup

Sourced once at login. Safe to be slightly heavier than `.zshenv`.

```zsh
# ── PATH ─────────────────────────────────────────────────────────────────────
export PATH="$PATH:$HOME/.local/bin"

{{ if eq .chezmoi.os "darwin" -}}
# Homebrew (Apple Silicon). Guard existence to handle pre-Homebrew state.
[[ -d /opt/homebrew/bin ]] && export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
{{ end -}}
```

**Note on Homebrew PATH prepend:** Homebrew binaries precede system binaries intentionally.
This is the standard setup and required for Homebrew-installed tools to shadow older system
versions (e.g., `git`, `curl`). The trust boundary is the Homebrew installation and its taps.
Only install formulae from trusted sources.

### `dot_zshrc.tmpl` — Interactive shell entry point

Thin file. Only sources modular config in explicit, deterministic order.

```zsh
# ── Load modular zsh config ───────────────────────────────────────────────────
# Explicit source order (not glob) — deterministic loading, no injection risk.
_zsh_config="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

source "$_zsh_config/history.zsh"
source "$_zsh_config/completion.zsh"
source "$_zsh_config/keybindings.zsh"
source "$_zsh_config/aliases.zsh"
source "$_zsh_config/mise.zsh"
source "$_zsh_config/sheldon.zsh"
source "$_zsh_config/starship.zsh"

unset _zsh_config
```

**Security decision — no glob source:** `for f in ~/.config/zsh/*.zsh; do source "$f"; done`
was rejected. Reasons:
1. Any file written to `~/.config/zsh/` (by a package manager hook, symlink, etc.) would
   execute at shell startup with full user privileges.
2. Glob ordering is filesystem-dependent; explicit ordering avoids subtle initialization bugs.
3. Symlink injection: a symlink pointing to any shell-interpretable file would be sourced.

### `dot_config/zsh/*.zsh` — Modular config files

Each file is self-contained and guards optional tools with `command -v`.

**`history.zsh`:**
```zsh
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_REDUCE_BLANKS HIST_IGNORE_SPACE
```

**`completion.zsh`:**
```zsh
autoload -Uz compinit && compinit
```

**`keybindings.zsh`:**
```zsh
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
```

**`aliases.zsh`:**
```zsh
if command -v eza &>/dev/null; then
    alias ls='eza --icons'
    alias ll='eza -lh --icons --git'
    alias la='eza -lha --icons --git'
    alias lt='eza --tree --icons'
fi
if command -v bat &>/dev/null; then
    alias cat='bat --paging=never'
fi
```

**`mise.zsh` / `sheldon.zsh` / `starship.zsh`:**
```zsh
# Each follows the same pattern:
if command -v <tool> &>/dev/null; then
    eval "$(<tool> activate zsh)"  # or equivalent init command
fi
```

Trust assumption: `eval` of tool output is unavoidable with these tools. Security depends
on binary integrity — install only via trusted package managers with pinned versions.

### `private_dot_config/chezmoi/chezmoi.toml.tmpl` — chezmoi configuration

```toml
# SECURITY: This file is committed to git. Never place secrets, tokens,
# API keys, passwords, or sensitive personal data here.
# Machine-specific secrets belong in ~/.config/chezmoi/chezmoi.toml (untracked).

[data]
# Use boolean flags for branching — avoid literal personal identifiers.
# Example: isWork = false
```

---

## Security Decisions

This plan incorporates the following changes from the initial proposal based on a pre-implementation
security review:

| Finding | Severity | Resolution |
|---------|----------|-----------|
| Glob source allows file injection | HIGH | Replaced with explicit ordered `source` calls |
| `.zshenv` has no content policy | HIGH | Added prohibited-content comment + bats test |
| `chezmoi.toml` `private_` doesn't protect git source | HIGH | Documented: no secrets in `.tmpl`; boolean flags only |
| `~/.config/zsh/` world-readable by default | MEDIUM | `run_once_` script sets `chmod 700 ~/.config/zsh` |
| Homebrew PATH lacks existence guard | MEDIUM | Added `[[ -d /opt/homebrew/bin ]]` guard |
| Template branching on literal personal values leaks PII | MEDIUM | Convention: boolean flags only in `chezmoi.toml.tmpl` |
| `eval` supply-chain trust dependency | MEDIUM | Documented as accepted risk; `command -v` guards in place |

---

## Directory Permissions

`~/.config/zsh/` must not be world-readable (it reveals toolchain and alias definitions).
chezmoi creates directories with umask-derived permissions (typically `755`).

Fix: add `home/run_once_set-zsh-config-permissions.sh`:
```zsh
#!/usr/bin/env zsh
chmod 700 "${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
```

chezmoi runs `run_once_` scripts exactly once (tracked by content hash).

---

## Tests to Add

### Existing tests to migrate/update

- `dot_zshrc.tmpl` syntax test → extend to cover all new files
- PATH export test → move to `dot_zprofile.tmpl`
- `darwin` branch test → move to `dot_zprofile.tmpl`

### New tests

```bash
# dot_zshenv has no syntax errors
@test "dot_zshenv.tmpl has no zsh syntax errors"

# dot_zshenv does not contain prohibited patterns
@test "dot_zshenv.tmpl contains no eval"
@test "dot_zshenv.tmpl contains no echo or printf"
@test "dot_zshenv.tmpl contains no PATH export"

# dot_zprofile
@test "dot_zprofile.tmpl has no zsh syntax errors"
@test "dot_zprofile.tmpl contains PATH export"
@test "dot_zprofile.tmpl handles darwin branch"
@test "dot_zprofile.tmpl guards Homebrew directory existence"

# dot_zshrc sources explicit files (no glob)
@test "dot_zshrc.tmpl does not use glob source pattern"

# Modular files
@test "history.zsh contains HISTFILE"
@test "history.zsh contains HIST_IGNORE_SPACE"
@test "aliases.zsh guards eza with command -v"
@test "aliases.zsh guards bat with command -v"
@test "mise.zsh guards mise with command -v"
@test "sheldon.zsh guards sheldon with command -v"
@test "starship.zsh guards starship with command -v"
```

---

## Implementation Phases

### Phase 1 — New files
1. Create `dot_zshenv.tmpl`
2. Create `dot_zprofile.tmpl` (move PATH + macOS block from current `dot_zshrc.tmpl`)
3. Rewrite `dot_zshrc.tmpl` to explicit source calls only
4. Create `dot_config/zsh/*.zsh` (move each section from current `dot_zshrc.tmpl`)
5. Create `private_dot_config/chezmoi/chezmoi.toml.tmpl`
6. Create `run_once_set-zsh-config-permissions.sh`

### Phase 2 — Tests
7. Update `tests/test_zsh.bats` — migrate existing tests, add new ones listed above

### Phase 3 — Cleanup
8. Remove content from `dot_zshrc.tmpl` that has been moved
9. Update `CLAUDE.md` repository structure diagram
10. Commit

---

## Risks

| Risk | Mitigation |
|------|-----------|
| `chezmoi.toml.tmpl` managed by chezmoi creates bootstrap dependency | First-time setup requires manual creation of `~/.config/chezmoi/chezmoi.toml` or accepting defaults from template |
| `run_once_` script runs only once — permission fix not re-applied if reverted | Document; add bats test to verify permissions |
| Modular file load errors fail silently if source file missing | chezmoi manages all files; absence implies chezmoi not applied |
