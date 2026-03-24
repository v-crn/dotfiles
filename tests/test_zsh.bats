#!/usr/bin/env bats
# Tests for zsh dotfile managed by chezmoi
# Run from repository root: bats tests/test_zsh.bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
CHEZMOI_ROOT="$(cat "$REPO_ROOT/.chezmoiroot" | tr -d '[:space:]')"
[[ "$CHEZMOI_ROOT" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Invalid .chezmoiroot value: $CHEZMOI_ROOT"; exit 1; }
DOT_ZSHRC="$REPO_ROOT/$CHEZMOI_ROOT/dot_zshrc.tmpl"
DOT_ZSHENV="$REPO_ROOT/$CHEZMOI_ROOT/dot_zshenv.tmpl"
DOT_ZPROFILE="$REPO_ROOT/$CHEZMOI_ROOT/dot_zprofile.tmpl"
ZSH_CONFIG_DIR="$REPO_ROOT/$CHEZMOI_ROOT/dot_config/zsh"

# ---------------------------------------------------------------------------
# File existence — dot_zshrc
# ---------------------------------------------------------------------------

@test "home/dot_zshrc.tmpl exists" {
    [ -f "$DOT_ZSHRC" ]
}

# ---------------------------------------------------------------------------
# Syntax check (strip chezmoi template directives before checking)
# ---------------------------------------------------------------------------

@test "dot_zshrc.tmpl has no zsh syntax errors after stripping templates" {
    stripped=$(grep -v '{{' "$DOT_ZSHRC")
    zsh -n <(echo "$stripped")
}

# ---------------------------------------------------------------------------
# Content: dot_zshrc is thin entry point sourcing modular files
# ---------------------------------------------------------------------------

@test "dot_zshrc.tmpl sources history.zsh" {
    grep -q 'history\.zsh' "$DOT_ZSHRC"
}

@test "dot_zshrc.tmpl sources completion.zsh" {
    grep -q 'completion\.zsh' "$DOT_ZSHRC"
}

@test "dot_zshrc.tmpl sources keybindings.zsh" {
    grep -q 'keybindings\.zsh' "$DOT_ZSHRC"
}

@test "dot_zshrc.tmpl sources aliases.zsh" {
    grep -q 'aliases\.zsh' "$DOT_ZSHRC"
}

@test "dot_zshrc.tmpl sources mise.zsh" {
    grep -q 'mise\.zsh' "$DOT_ZSHRC"
}

@test "dot_zshrc.tmpl sources sheldon.zsh" {
    grep -q 'sheldon\.zsh' "$DOT_ZSHRC"
}

@test "dot_zshrc.tmpl sources starship.zsh" {
    grep -q 'starship\.zsh' "$DOT_ZSHRC"
}

@test "dot_zshrc.tmpl does not use glob source pattern" {
    # Explicit source calls only — no glob injection risk
    ! grep -qE 'for .* in .*\*.*\.zsh' "$DOT_ZSHRC"
}

# ---------------------------------------------------------------------------
# File existence — dot_zshenv
# ---------------------------------------------------------------------------

@test "home/dot_zshenv.tmpl exists" {
    [ -f "$DOT_ZSHENV" ]
}

@test "dot_zshenv.tmpl has no zsh syntax errors" {
    stripped=$(grep -v '{{' "$DOT_ZSHENV")
    zsh -n <(echo "$stripped")
}

@test "dot_zshenv.tmpl sets XDG_CONFIG_HOME" {
    grep -q 'XDG_CONFIG_HOME' "$DOT_ZSHENV"
}

@test "dot_zshenv.tmpl sets EDITOR" {
    grep -q 'EDITOR' "$DOT_ZSHENV"
}

@test "dot_zshenv.tmpl sets LANG" {
    grep -q 'LANG' "$DOT_ZSHENV"
}

@test "dot_zshenv.tmpl contains no eval" {
    # eval is prohibited in zshenv — it runs for ALL shells including cron/SSH
    ! grep -qE '^\s*eval\b' "$DOT_ZSHENV"
}

@test "dot_zshenv.tmpl contains no echo or printf" {
    # Output is prohibited — breaks SSH scp/rsync/sftp
    ! grep -qE '^\s*(echo|printf)\b' "$DOT_ZSHENV"
}

@test "dot_zshenv.tmpl contains no PATH export" {
    # PATH modifications belong in dot_zprofile.tmpl
    ! grep -q 'export PATH' "$DOT_ZSHENV"
}

# ---------------------------------------------------------------------------
# File existence — dot_zprofile
# ---------------------------------------------------------------------------

@test "home/dot_zprofile.tmpl exists" {
    [ -f "$DOT_ZPROFILE" ]
}

@test "dot_zprofile.tmpl has no zsh syntax errors" {
    stripped=$(grep -v '{{' "$DOT_ZPROFILE")
    zsh -n <(echo "$stripped")
}

@test "dot_zprofile.tmpl contains PATH export" {
    grep -q 'export PATH' "$DOT_ZPROFILE"
}

@test "dot_zprofile.tmpl handles darwin branch" {
    grep -q 'darwin' "$DOT_ZPROFILE"
}

@test "dot_zprofile.tmpl guards Homebrew directory existence" {
    grep -q '\[\[ -d /opt/homebrew/bin \]\]' "$DOT_ZPROFILE"
}

# ---------------------------------------------------------------------------
# Modular files — history.zsh
# ---------------------------------------------------------------------------

@test "history.zsh exists" {
    [ -f "$ZSH_CONFIG_DIR/history.zsh" ]
}

@test "history.zsh contains HISTFILE" {
    grep -q 'HISTFILE' "$ZSH_CONFIG_DIR/history.zsh"
}

@test "history.zsh contains HIST_IGNORE_SPACE" {
    grep -q 'HIST_IGNORE_SPACE' "$ZSH_CONFIG_DIR/history.zsh"
}

# ---------------------------------------------------------------------------
# Modular files — completion.zsh
# ---------------------------------------------------------------------------

@test "completion.zsh exists" {
    [ -f "$ZSH_CONFIG_DIR/completion.zsh" ]
}

@test "completion.zsh contains compinit" {
    grep -q 'compinit' "$ZSH_CONFIG_DIR/completion.zsh"
}

# ---------------------------------------------------------------------------
# Modular files — keybindings.zsh
# ---------------------------------------------------------------------------

@test "keybindings.zsh exists" {
    [ -f "$ZSH_CONFIG_DIR/keybindings.zsh" ]
}

# ---------------------------------------------------------------------------
# Modular files — aliases.zsh
# ---------------------------------------------------------------------------

@test "aliases.zsh exists" {
    [ -f "$ZSH_CONFIG_DIR/aliases.zsh" ]
}

@test "aliases.zsh guards eza with command -v" {
    grep -q 'command -v eza' "$ZSH_CONFIG_DIR/aliases.zsh"
}

@test "aliases.zsh guards bat with command -v" {
    grep -q 'command -v bat' "$ZSH_CONFIG_DIR/aliases.zsh"
}

# ---------------------------------------------------------------------------
# Modular files — mise.zsh
# ---------------------------------------------------------------------------

@test "mise.zsh exists" {
    [ -f "$ZSH_CONFIG_DIR/mise.zsh" ]
}

@test "mise.zsh guards mise with command -v" {
    grep -q 'command -v mise' "$ZSH_CONFIG_DIR/mise.zsh"
}

# ---------------------------------------------------------------------------
# Modular files — sheldon.zsh
# ---------------------------------------------------------------------------

@test "sheldon.zsh exists" {
    [ -f "$ZSH_CONFIG_DIR/sheldon.zsh" ]
}

@test "sheldon.zsh guards sheldon with command -v" {
    grep -q 'command -v sheldon' "$ZSH_CONFIG_DIR/sheldon.zsh"
}

# ---------------------------------------------------------------------------
# Modular files — starship.zsh
# ---------------------------------------------------------------------------

@test "starship.zsh exists" {
    [ -f "$ZSH_CONFIG_DIR/starship.zsh" ]
}

@test "starship.zsh guards starship with command -v" {
    grep -q 'command -v starship' "$ZSH_CONFIG_DIR/starship.zsh"
}

# ---------------------------------------------------------------------------
# chezmoi managed files
# ---------------------------------------------------------------------------

@test "chezmoi manages .zshrc" {
    chezmoi init --source "$REPO_ROOT" 2>/dev/null || true
    chezmoi managed | grep -q '\.zshrc'
}

@test "chezmoi manages .zshenv" {
    chezmoi init --source "$REPO_ROOT" 2>/dev/null || true
    chezmoi managed | grep -q '\.zshenv'
}

@test "chezmoi manages .zprofile" {
    chezmoi init --source "$REPO_ROOT" 2>/dev/null || true
    chezmoi managed | grep -q '\.zprofile'
}
