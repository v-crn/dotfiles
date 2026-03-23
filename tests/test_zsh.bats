#!/usr/bin/env bats
# Tests for zsh dotfile managed by chezmoi
# Run from repository root: bats tests/test_zsh.bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
DOT_ZSHRC="$REPO_ROOT/home/dot_zshrc"

# ---------------------------------------------------------------------------
# File existence
# ---------------------------------------------------------------------------

@test "home/dot_zshrc exists" {
    [ -f "$DOT_ZSHRC" ]
}

# ---------------------------------------------------------------------------
# Syntax check
# ---------------------------------------------------------------------------

@test "dot_zshrc has no zsh syntax errors" {
    zsh -n "$DOT_ZSHRC"
}

# ---------------------------------------------------------------------------
# Content: History section
# ---------------------------------------------------------------------------

@test "dot_zshrc contains HISTFILE setting" {
    grep -q 'HISTFILE' "$DOT_ZSHRC"
}

@test "dot_zshrc contains HISTSIZE setting" {
    grep -q 'HISTSIZE' "$DOT_ZSHRC"
}

@test "dot_zshrc contains SAVEHIST setting" {
    grep -q 'SAVEHIST' "$DOT_ZSHRC"
}

# ---------------------------------------------------------------------------
# Content: Completion section
# ---------------------------------------------------------------------------

@test "dot_zshrc contains compinit" {
    grep -q 'compinit' "$DOT_ZSHRC"
}

# ---------------------------------------------------------------------------
# Content: PATH section
# ---------------------------------------------------------------------------

@test "dot_zshrc contains PATH export" {
    grep -q 'export PATH' "$DOT_ZSHRC"
}

# ---------------------------------------------------------------------------
# chezmoi managed files
# ---------------------------------------------------------------------------

@test "chezmoi manages .zshrc" {
    # Initialize chezmoi with our source directory if not already done
    chezmoi init --source "$REPO_ROOT" 2>/dev/null || true
    chezmoi managed | grep -q '\.zshrc'
}
