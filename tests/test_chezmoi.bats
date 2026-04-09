#!/usr/bin/env bats
# Tests for chezmoi management
# Run from repository root: bats tests/test_chezmoi.bats

setup() {
    load 'test_helper.sh'
    setup_common
}

@test "chezmoi manages core zsh files" {
    # .zshrc, .zshenv, .zprofile
    chezmoi --source "$REPO_ROOT" managed | grep -q '\.zshrc'
    chezmoi --source "$REPO_ROOT" managed | grep -q '\.zshenv'
    chezmoi --source "$REPO_ROOT" managed | grep -q '\.zprofile'
}

@test "chezmoi manages sheldon and starship config" {
    chezmoi --source "$REPO_ROOT" managed | grep -q '\.config/sheldon/plugins\.toml'
    chezmoi --source "$REPO_ROOT" managed | grep -q '\.config/starship\.toml'
}
