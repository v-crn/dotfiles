#!/bin/bash
# Detect the current platform and export PLATFORM.
# Values: macos | wsl | linux | unknown
# Source this file: . platform.sh
# After sourcing, $PLATFORM is set and exported.

_detect_platform() {
    if [ "$(uname -s 2>/dev/null)" = "Darwin" ]; then
        echo "macos"
    elif [ -n "${WSL_DISTRO_NAME:-}" ]; then
        echo "wsl"
    elif [ "$(uname -s 2>/dev/null)" = "Linux" ]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

PLATFORM="$(_detect_platform)"
export PLATFORM
