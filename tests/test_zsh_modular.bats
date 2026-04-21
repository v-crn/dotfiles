#!/usr/bin/env bats
# Tests for modular zsh files
# Run from repository root: bats tests/test_zsh_modular.bats

setup() {
    load 'test_helper.sh'
    setup_common
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
# Modular files — 60_completion.zsh
# ---------------------------------------------------------------------------

@test "60_completion.zsh exists" {
    [ -f "$ZSH_CONFIG_DIR/60_completion.zsh" ]
}

@test "60_completion.zsh contains compinit" {
    grep -q 'compinit' "$ZSH_CONFIG_DIR/60_completion.zsh"
}

# ---------------------------------------------------------------------------
# Modular files — keybindings.zsh
# ---------------------------------------------------------------------------

@test "keybindings.zsh exists" {
    [ -f "$ZSH_CONFIG_DIR/keybindings.zsh" ]
}

@test "keybindings.zsh conditionally binds history-substring-search" {
    grep -q 'history-substring-search-up' "$ZSH_CONFIG_DIR/keybindings.zsh"
}

# ---------------------------------------------------------------------------
# Modular files — eza.zsh
# ---------------------------------------------------------------------------

@test "eza.zsh exists" {
    [ -f "$ZSH_CONFIG_DIR/eza.zsh" ]
}

@test "eza.zsh guards eza with command -v" {
    grep -q 'command -v eza' "$ZSH_CONFIG_DIR/eza.zsh"
}

# ---------------------------------------------------------------------------
# Modular files — bat.zsh
# ---------------------------------------------------------------------------

@test "bat.zsh exists" {
    [ -f "$ZSH_CONFIG_DIR/bat.zsh" ]
}

@test "bat.zsh guards bat with command -v" {
    grep -q 'command -v bat' "$ZSH_CONFIG_DIR/bat.zsh"
}

@test "bat.zsh guards batcat with command -v" {
    grep -q 'command -v batcat' "$ZSH_CONFIG_DIR/bat.zsh"
}

@test "bat.zsh defines bat alias for batcat" {
    grep -q "alias bat='batcat'" "$ZSH_CONFIG_DIR/bat.zsh"
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

@test "mise.zsh uses shims activation" {
    grep -q 'mise activate zsh --shims' "$ZSH_CONFIG_DIR/mise.zsh"
}

# ---------------------------------------------------------------------------
# Modular files — 50_sheldon.zsh
# ---------------------------------------------------------------------------

@test "50_sheldon.zsh exists" {
    [ -f "$ZSH_CONFIG_DIR/50_sheldon.zsh" ]
}

@test "50_sheldon.zsh guards sheldon with command -v" {
    grep -q 'command -v sheldon' "$ZSH_CONFIG_DIR/50_sheldon.zsh"
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
# Load order and conditional sourcing
# ---------------------------------------------------------------------------

@test "60_completion.zsh sources fzf-tab conditionally after compinit" {
    compinit_line=$(grep -n 'compinit' "$ZSH_CONFIG_DIR/60_completion.zsh" | head -1 | cut -d: -f1)
    fzftab_line=$(grep -n 'fzf-tab' "$ZSH_CONFIG_DIR/60_completion.zsh" | head -1 | cut -d: -f1)
    [ -n "$compinit_line" ] && [ -n "$fzftab_line" ]
    [ "$compinit_line" -lt "$fzftab_line" ]
}

@test "60_completion.zsh guards fzf-tab with command -v fzf" {
    grep -q 'command -v fzf' "$ZSH_CONFIG_DIR/60_completion.zsh"
}

@test "50_sheldon.zsh sorts before 60_completion.zsh" {
    [ -f "$ZSH_CONFIG_DIR/50_sheldon.zsh" ]
    [ -f "$ZSH_CONFIG_DIR/60_completion.zsh" ]
    [[ "50_sheldon.zsh" < "60_completion.zsh" ]]
}
