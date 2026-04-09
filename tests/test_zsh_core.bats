#!/usr/bin/env bats
# Tests for core zsh dotfiles managed by chezmoi
# Run from repository root: bats tests/test_zsh_core.bats

setup() {
    load 'test_helper.sh'
    setup_common
}

# ---------------------------------------------------------------------------
# dot_zshrc
# ---------------------------------------------------------------------------

@test "home/dot_zshrc.tmpl exists" {
    [ -f "$DOT_ZSHRC" ]
}

@test "dot_zshrc.tmpl has no zsh syntax errors after stripping templates" {
    stripped=$(grep -v '{{' "$DOT_ZSHRC")
    zsh -n <(echo "$stripped")
}

@test "dot_zshrc.tmpl uses glob source pattern" {
    grep -qE 'for .+ in .+\*\.zsh' "$DOT_ZSHRC"
}

# ---------------------------------------------------------------------------
# dot_zshenv
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
    ! grep -qE '^\s*eval\b' "$DOT_ZSHENV"
}

@test "dot_zshenv.tmpl contains no echo or printf" {
    ! grep -qE '^\s*(echo|printf)\b' "$DOT_ZSHENV"
}

@test "dot_zshenv.tmpl contains no PATH export" {
    ! grep -q 'export PATH' "$DOT_ZSHENV"
}

# ---------------------------------------------------------------------------
# dot_zprofile
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
