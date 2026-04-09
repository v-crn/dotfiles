#!/usr/bin/env bash
# shellcheck disable=SC2034

setup_common() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    CHEZMOI_ROOT="$(tr -d '[:space:]' < "$REPO_ROOT/.chezmoiroot")"
    [[ "$CHEZMOI_ROOT" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Invalid .chezmoiroot value: $CHEZMOI_ROOT"; exit 1; }
    
    DOT_ZSHRC="$REPO_ROOT/$CHEZMOI_ROOT/dot_zshrc.tmpl"
    DOT_ZSHENV="$REPO_ROOT/$CHEZMOI_ROOT/dot_zshenv.tmpl"
    DOT_ZPROFILE="$REPO_ROOT/$CHEZMOI_ROOT/dot_zprofile.tmpl"
    ZSH_CONFIG_DIR="$REPO_ROOT/$CHEZMOI_ROOT/dot_config/zsh"
    SHELDON_CONFIG_DIR="$REPO_ROOT/$CHEZMOI_ROOT/dot_config/sheldon"
    STARSHIP_CONFIG="$REPO_ROOT/$CHEZMOI_ROOT/dot_config/starship.toml"
}
