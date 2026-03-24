#!/usr/bin/env bats
# Tests for zsh dotfile managed by chezmoi
# Run from repository root: bats tests/test_zsh.bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
CHEZMOI_ROOT="$(cat "$REPO_ROOT/.chezmoiroot" | tr -d '[:space:]')"
DOT_ZSHRC="$REPO_ROOT/$CHEZMOI_ROOT/dot_zshrc.tmpl"

# ---------------------------------------------------------------------------
# File existence
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
# Cross-platform: template directives present
# ---------------------------------------------------------------------------

@test "dot_zshrc uses chezmoi OS template for platform-specific config" {
    grep -q '\.chezmoi\.os' "$DOT_ZSHRC"
}

@test "dot_zshrc handles macOS (darwin) branch" {
    grep -q 'darwin' "$DOT_ZSHRC"
}

# ---------------------------------------------------------------------------
# chezmoi managed files
# ---------------------------------------------------------------------------

@test "chezmoi manages .zshrc" {
    chezmoi init --source "$REPO_ROOT" 2>/dev/null || true
    chezmoi managed | grep -q '\.zshrc'
}
