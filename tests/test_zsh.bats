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
# Content: dot_zshrc is thin entry point sourcing modular files via glob
# ---------------------------------------------------------------------------

@test "dot_zshrc.tmpl uses glob source pattern" {
    grep -qE 'for .+ in .+\*\.zsh' "$DOT_ZSHRC"
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

@test "aliases.zsh guards batcat with command -v" {
    grep -q 'command -v batcat' "$ZSH_CONFIG_DIR/aliases.zsh"
}

@test "aliases.zsh defines bat alias for batcat" {
    grep -q "alias bat='batcat'" "$ZSH_CONFIG_DIR/aliases.zsh"
}

@test "aliases.zsh defines cat alias in batcat branch" {
    grep -q "alias cat='batcat --paging=never'" "$ZSH_CONFIG_DIR/aliases.zsh"
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
# chezmoi managed files
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# sheldon -- plugins.toml
# ---------------------------------------------------------------------------

SHELDON_CONFIG_DIR="$REPO_ROOT/$CHEZMOI_ROOT/dot_config/sheldon"

@test "dot_config/sheldon/plugins.toml exists" {
    [ -f "$SHELDON_CONFIG_DIR/plugins.toml" ]
}

@test "plugins.toml declares shell = zsh" {
    grep -q '^shell = "zsh"' "$SHELDON_CONFIG_DIR/plugins.toml"
}

@test "plugins.toml contains at least one plugin section" {
    grep -qE '^\[plugins\.' "$SHELDON_CONFIG_DIR/plugins.toml"
}

@test "plugins.toml includes zsh-autosuggestions" {
    grep -q 'zsh-users/zsh-autosuggestions' "$SHELDON_CONFIG_DIR/plugins.toml"
}

@test "plugins.toml includes zsh-syntax-highlighting" {
    grep -q 'zsh-users/zsh-syntax-highlighting' "$SHELDON_CONFIG_DIR/plugins.toml"
}

@test "plugins.toml includes zsh-autopair" {
    grep -q 'hlissner/zsh-autopair' "$SHELDON_CONFIG_DIR/plugins.toml"
}

@test "plugins.toml includes zsh-you-should-use" {
    grep -q 'MichaelAquilina/zsh-you-should-use' "$SHELDON_CONFIG_DIR/plugins.toml"
}

@test "plugins.toml includes fzf-tab" {
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

@test "60_completion.zsh sources fzf-tab conditionally after compinit" {
    # fzf-tab source must appear after compinit line
    compinit_line=$(grep -n 'compinit' "$ZSH_CONFIG_DIR/60_completion.zsh" | head -1 | cut -d: -f1)
    fzftab_line=$(grep -n 'fzf-tab' "$ZSH_CONFIG_DIR/60_completion.zsh" | head -1 | cut -d: -f1)
    [ -n "$compinit_line" ] && [ -n "$fzftab_line" ]
    [ "$compinit_line" -lt "$fzftab_line" ]
}

@test "60_completion.zsh guards fzf-tab with command -v fzf" {
    grep -q 'command -v fzf' "$ZSH_CONFIG_DIR/60_completion.zsh"
}

# ---------------------------------------------------------------------------
# Load order: 50_sheldon.zsh before 60_completion.zsh (via filename sort)
# ---------------------------------------------------------------------------

@test "50_sheldon.zsh sorts before 60_completion.zsh" {
    # Numeric prefix guarantees correct glob load order
    [ -f "$ZSH_CONFIG_DIR/50_sheldon.zsh" ]
    [ -f "$ZSH_CONFIG_DIR/60_completion.zsh" ]
    [[ "50_sheldon.zsh" < "60_completion.zsh" ]]
}

# ---------------------------------------------------------------------------
# chezmoi managed files
# ---------------------------------------------------------------------------

@test "chezmoi manages .zshrc" {
    chezmoi --source "$REPO_ROOT" managed | grep -q '\.zshrc'
}

@test "chezmoi manages .zshenv" {
    chezmoi --source "$REPO_ROOT" managed | grep -q '\.zshenv'
}

@test "chezmoi manages .zprofile" {
    chezmoi --source "$REPO_ROOT" managed | grep -q '\.zprofile'
}

@test "chezmoi manages .config/sheldon/plugins.toml" {
    chezmoi --source "$REPO_ROOT" managed | grep -q '\.config/sheldon/plugins\.toml'
}

@test "chezmoi manages .config/starship.toml" {
    chezmoi --source "$REPO_ROOT" managed | grep -q '\.config/starship\.toml'
}

# ---------------------------------------------------------------------------
# starship.toml
# ---------------------------------------------------------------------------

STARSHIP_CONFIG="$REPO_ROOT/$CHEZMOI_ROOT/dot_config/starship.toml"

@test "dot_config/starship.toml exists" {
    [ -f "$STARSHIP_CONFIG" ]
}

@test "starship.toml defines top-level format" {
    grep -q '^format = ' "$STARSHIP_CONFIG"
}

@test "starship.toml defines right_format" {
    grep -q '^right_format = ' "$STARSHIP_CONFIG"
}

@test "starship.toml includes character module" {
    grep -q '^\[character\]' "$STARSHIP_CONFIG"
}

@test "starship.toml includes directory module" {
    grep -q '^\[directory\]' "$STARSHIP_CONFIG"
}

@test "starship.toml includes git_branch module" {
    grep -q '^\[git_branch\]' "$STARSHIP_CONFIG"
}

@test "starship.toml includes git_status module" {
    grep -q '^\[git_status\]' "$STARSHIP_CONFIG"
}

@test "starship.toml disables battery module" {
    awk '/^\[battery\]/{found=1} found && /disabled/{print; exit}' "$STARSHIP_CONFIG" \
        | grep -q 'disabled = true'
}

@test "starship.toml disables aws module" {
    awk '/^\[aws\]/{found=1} found && /disabled/{print; exit}' "$STARSHIP_CONFIG" \
        | grep -q 'disabled = true'
}

@test "starship.toml contains no secrets" {
    ! grep -qiE '(api_?key|token|password|secret)\s*=' "$STARSHIP_CONFIG"
}
