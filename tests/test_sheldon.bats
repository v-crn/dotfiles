#!/usr/bin/env bats
# Tests for sheldon configuration
# Run from repository root: bats tests/test_sheldon.bats

setup() {
    load 'test_helper.sh'
    setup_common
}

@test "dot_config/sheldon/plugins.toml exists" {
    [ -f "$SHELDON_CONFIG_DIR/plugins.toml" ]
}

@test "plugins.toml declares shell = zsh" {
    grep -q '^shell = "zsh"' "$SHELDON_CONFIG_DIR/plugins.toml"
}

@test "plugins.toml contains at least one plugin section" {
    grep -qE '^\[plugins\.' "$SHELDON_CONFIG_DIR/plugins.toml"
}

@test "plugins.toml includes key plugins" {
    grep -q 'zsh-users/zsh-syntax-highlighting' "$SHELDON_CONFIG_DIR/plugins.toml"
    grep -q 'Aloxaf/fzf-tab' "$SHELDON_CONFIG_DIR/plugins.toml"
}

@test "fzf-tab has apply = [] in plugins.toml" {
    # fzf-tab must not be sourced by sheldon; it is sourced after compinit in 60_completion.zsh
    awk '/\[plugins\.fzf-tab\]/{found=1} found && /apply/{print; exit}' "$SHELDON_CONFIG_DIR/plugins.toml" \
        | grep -q 'apply = \[\]'
}

@test "plugins.toml has zsh-syntax-highlighting as the last plugin" {
    last_plugin=$(grep -E '^\[plugins\.' "$SHELDON_CONFIG_DIR/plugins.toml" | tail -1)
    [[ "$last_plugin" == *"zsh-syntax-highlighting"* ]]
}

@test "plugins.toml contains no secrets" {
    ! grep -qiE '(api_?key|token|password|secret)\s*=' "$SHELDON_CONFIG_DIR/plugins.toml"
}
