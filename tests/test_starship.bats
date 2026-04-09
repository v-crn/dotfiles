#!/usr/bin/env bats
# Tests for starship configuration
# Run from repository root: bats tests/test_starship.bats

setup() {
    load 'test_helper.sh'
    setup_common
}

@test "dot_config/starship.toml exists" {
    [ -f "$STARSHIP_CONFIG" ]
}

@test "starship.toml defines top-level format" {
    grep -q '^format = ' "$STARSHIP_CONFIG"
}

@test "starship.toml includes character module" {
    grep -q '^\[character\]' "$STARSHIP_CONFIG"
}

@test "starship.toml contains no secrets" {
    ! grep -qiE '(api_?key|token|password|secret)\s*=' "$STARSHIP_CONFIG"
}
