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

@test "shared agent template renders the same rules for agents entrypoints" {
    local agents_output claude_output gemini_output codex_output

    agents_output="$(chezmoi execute-template --source "$REPO_ROOT" < "$REPO_ROOT/home/dot_agents/AGENTS.md.tmpl")"
    claude_output="$(chezmoi execute-template --source "$REPO_ROOT" < "$REPO_ROOT/home/dot_claude/CLAUDE.md.tmpl")"
    gemini_output="$(chezmoi execute-template --source "$REPO_ROOT" < "$REPO_ROOT/home/dot_gemini/GEMINI.md.tmpl")"
    codex_output="$(chezmoi execute-template --source "$REPO_ROOT" < "$REPO_ROOT/home/dot_codex/AGENTS.md.tmpl")"

    [ "$claude_output" = "$agents_output" ]
    [ "$gemini_output" = "$agents_output" ]
    [ "$codex_output" = "$agents_output" ]
    [[ "$agents_output" == *"## Security Guidelines"* ]]
}

@test "cursor global rule inlines the shared agent template body" {
    local agents_output cursor_output cursor_body

    agents_output="$(chezmoi execute-template --source "$REPO_ROOT" < "$REPO_ROOT/home/dot_agents/AGENTS.md.tmpl")"
    cursor_output="$(chezmoi execute-template --source "$REPO_ROOT" < "$REPO_ROOT/home/dot_cursor/rules/global.mdc.tmpl")"
    cursor_body="$(printf '%s\n' "$cursor_output" | sed '1,/^---$/d' | sed '/./,$!d')"

    [[ "$cursor_output" == *"alwaysApply: true"* ]]
    [ "$cursor_body" = "$agents_output" ]
}
