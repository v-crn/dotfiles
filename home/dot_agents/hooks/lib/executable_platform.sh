#!/bin/bash
# Detect the current platform and export PLATFORM.
# Values: macos | wsl | linux | unknown
# Source this file: . platform.sh
# After sourcing, $PLATFORM is set and exported.

_detect_platform() {
    local kernel
    local osrelease
    local proc_version
    kernel="$(uname -s 2>/dev/null)"
    if [ "$kernel" = "Darwin" ]; then
        echo "macos"
    elif [ -n "${WSL_DISTRO_NAME:-}" ]; then
        echo "wsl"
    elif [ "$kernel" = "Linux" ]; then
        osrelease="$(cat /proc/sys/kernel/osrelease 2>/dev/null || true)"
        proc_version="$(cat /proc/version 2>/dev/null || true)"
        case "$osrelease $proc_version" in
            *[Mm]icrosoft*|*[Ww][Ss][Ll]*)
                echo "wsl"
                ;;
            *)
                echo "linux"
                ;;
        esac
    else
        echo "unknown"
    fi
}

PLATFORM="$(_detect_platform)"
export PLATFORM
