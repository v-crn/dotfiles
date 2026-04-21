#!/bin/bash
# Shared .env filename policy.
# Return 0 when the given path should be treated as sensitive.

is_sensitive_env_file() {
    local base stripped old_ifs segment

    base="$(basename "$1")"
    case "$base" in
        .env|.env.*) ;;
        *)
            return 1
            ;;
    esac

    stripped="${base#.}"
    old_ifs="$IFS"
    IFS='.'
    # shellcheck disable=SC2086
    set -- $stripped
    IFS="$old_ifs"

    for segment; do
        case "$segment" in
            example|template|sample|default|dist|schema)
                return 1
                ;;
        esac
    done

    return 0
}
