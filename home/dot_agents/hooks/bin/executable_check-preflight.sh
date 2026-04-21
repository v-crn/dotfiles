#!/bin/bash
# Shared preflight CLI.
# Usage: check-preflight.sh TOOL_NAME FILE_PATH COMMAND

tool_name="${1:-}"
file_path="${2:-}"
command="${3:-}"

load_shared_lib() {
    local lib_name="$1"
    local script_dir candidate

    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    for candidate in \
        "$script_dir/../lib/${lib_name}.sh" \
        "$script_dir/../lib/executable_${lib_name}.sh" \
        "$HOME/.agents/hooks/lib/${lib_name}.sh" \
        "$HOME/.agents/hooks/lib/executable_${lib_name}.sh"
    do
        if [ -r "$candidate" ]; then
            # shellcheck disable=SC1090,SC1091
            . "$candidate" || {
                printf 'Blocked: failed to load shared hook library: %s\n' "$candidate" >&2
                exit 2
            }
            return 0
        fi
    done

    printf 'Blocked: missing shared hook library: %s\n' "$lib_name" >&2
    exit 2
}

load_shared_lib env_policy
load_shared_lib bash_policy

case "$tool_name" in
    Read|Edit|MultiEdit|Write)
        if [ -n "$file_path" ] && is_sensitive_env_file "$file_path"; then
            printf 'Blocked: %s is a sensitive .env file. Use .env.example (or similar) for templates.\n' \
                "$(basename "$file_path")" >&2
            exit 2
        fi
        ;;
    Bash)
        check_dangerous_bash_command "$command"
        exit $?
        ;;
esac

exit 0
