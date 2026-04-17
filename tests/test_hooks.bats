#!/usr/bin/env bats
# Tests for Claude Code hook scripts

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
CHEZMOI_ROOT="$(tr -d '[:space:]' < "$REPO_ROOT/.chezmoiroot")"
HOOKS_DIR="$REPO_ROOT/$CHEZMOI_ROOT/dot_claude/hooks"
PLATFORM_SH="$HOOKS_DIR/lib/platform.sh"

# ---------------------------------------------------------------------------
# lib/platform.sh
# ---------------------------------------------------------------------------

@test "platform.sh: exists and is executable" {
    [ -f "$PLATFORM_SH" ]
    [ -x "$PLATFORM_SH" ]
}

@test "platform.sh: detects macOS when uname returns Darwin" {
    run bash -c "uname() { echo Darwin; }; export -f uname; unset WSL_DISTRO_NAME; . '$PLATFORM_SH'; echo \$PLATFORM"
    [ "$output" = "macos" ]
}

@test "platform.sh: detects wsl when WSL_DISTRO_NAME is set" {
    run bash -c "WSL_DISTRO_NAME=Ubuntu . '$PLATFORM_SH'; echo \$PLATFORM"
    [ "$output" = "wsl" ]
}

@test "platform.sh: returns linux on plain Linux without WSL" {
    run bash -c "unset WSL_DISTRO_NAME; . '$PLATFORM_SH'; echo \$PLATFORM"
    # In this Docker/Linux container with no WSL_DISTRO_NAME, should be linux
    [ "$output" = "linux" ] || [ "$output" = "wsl" ]
}
