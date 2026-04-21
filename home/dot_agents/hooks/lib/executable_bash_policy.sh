#!/bin/bash
# Shared Bash preflight checks.
# Return 2 to block, 0 to allow. Warnings go to stderr.

load_shared_lib() {
    local lib_name="$1"
    local script_dir candidate

    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    for candidate in \
        "$script_dir/${lib_name}.sh" \
        "$script_dir/executable_${lib_name}.sh" \
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

strip_wrapping_quotes() {
    local token="$1"

    token="${token#\"}"
    token="${token%\"}"
    token="${token#\'}"
    token="${token%\'}"

    printf '%s' "$token"
}

strip_trailing_separators() {
    local token="$1"

    while [ -n "$token" ]; do
        case "$token" in
            *';')
                token="${token%;}"
                ;;
            *'&')
                token="${token%&}"
                ;;
            *'|')
                token="${token%|}"
                ;;
            *)
                break
                ;;
        esac
    done

    printf '%s' "$token"
}

is_env_assignment_token() {
    case "$1" in
        [A-Za-z_]*=*)
            return 0
            ;;
    esac

    return 1
}

is_wrapper_option() {
    case "$1" in
        -u|-g|-p|-h|-r|-t|-c|-s|-E|-H|-i|--user|--group|--prompt|--host|--role|--type|--command|--login|--preserve-env|--set-home)
            return 0
            ;;
    esac

    return 1
}

is_sql_client_command() {
    case "$1" in
        psql|*/psql|mysql|*/mysql|sqlite3|*/sqlite3|mariadb|*/mariadb|sqlcmd|*/sqlcmd|duckdb|*/duckdb)
            return 0
            ;;
    esac

    return 1
}

command_pipes_into_sql_client() {
    case "$1" in
        *\|*psql*|*\|*mysql*|*\|*sqlite3*|*\|*mariadb*|*\|*sqlcmd*|*\|*duckdb*)
            return 0
            ;;
    esac

    return 1
}

strip_command_wrappers() {
    local token

    set -f
    # shellcheck disable=SC2046
    set -- $(printf '%s' "$1" | xargs -n1 printf '%s\n')
    set +f

    while [ $# -gt 0 ]; do
        token="${1:-}"
        case "$token" in
            sudo|*/sudo|command|*/command)
                shift
                while [ $# -gt 0 ]; do
                    case "${1:-}" in
                        --)
                            shift
                            break
                            ;;
                        -i|-E|-H|-s|-l|--login|--preserve-env|--set-home)
                            shift
                            ;;
                        -u|-g|-p|-h|-r|-t|-c|--user|--group|--prompt|--host|--role|--type|--command)
                            shift
                            [ $# -gt 0 ] && shift
                            ;;
                        -*)
                            shift
                            ;;
                        *)
                            break
                            ;;
                    esac
                done
                ;;
            env|*/env)
                shift
                while [ $# -gt 0 ]; do
                    token="${1:-}"
                    case "$token" in
                        --)
                            shift
                            break
                            ;;
                        -i|-E|-H|--ignore-environment|--login|--preserve-env|--set-home)
                            shift
                            ;;
                        -u|-C|--chdir|--unset)
                            shift
                            [ $# -gt 0 ] && shift
                            ;;
                        -S|--split-string)
                            shift
                            break
                            ;;
                        -[!-]*)
                            shift
                            ;;
                        [A-Za-z_]*=*)
                            shift
                            ;;
                        *)
                            break
                            ;;
                    esac
                done
                ;;
            bash|*/bash|sh|*/sh|zsh|*/zsh|dash|*/dash)
                shift
                while [ $# -gt 0 ]; do
                    case "${1:-}" in
                        --)
                            shift
                            break
                            ;;
                        -*c*)
                            shift
                            break
                            ;;
                        -*)
                            shift
                            ;;
                        *)
                            break
                            ;;
                    esac
                done
                ;;
            *)
                break
                ;;
        esac
    done

    printf '%s\n' "$*"
}

is_destructive_rm_target() {
    local token

    token="$(strip_trailing_separators "$(strip_wrapping_quotes "$1")")"

    # shellcheck disable=SC2016
    if printf '%s' "$token" | grep -Eq '^(\/|~|\.|\/\*|~\/\*|\.\/\*|~\/|\.\/|\$HOME|\$\{HOME\})$'; then
        return 0
    fi

    return 1
}

is_sensitive_env_token() {
    local token base

    token="$(strip_trailing_separators "$(strip_wrapping_quotes "$1")")"

    if printf '%s' "$token" | grep -Eq '(^|.*/)\.env(\.|/|$)'; then
        base="$(basename "$token")"
        is_sensitive_env_file "$base"
        return $?
    fi

    return 1
}

command_contains_sensitive_env_read() {
    local token

    for token in "$@"; do
        if is_sensitive_env_token "$token"; then
            printf '%s\n' "$(strip_trailing_separators "$(strip_wrapping_quotes "$token")")"
            return 0
        fi
    done

    return 1
}

normalize_sql_text() {
    printf '%s' "$1" \
        | sed -E 's:/\*([^*]|\*+[^*/])*\*/: :g; s:--[^\n]*: :g' \
        | tr '\r\n\t' '   ' \
        | tr '[:lower:]' '[:upper:]'
}

command_uses_rm() {
    case "${1:-}" in
        rm|*/rm)
            return 0
            ;;
    esac

    return 1
}

check_dangerous_bash_command() {
    local command env_ref first_token token target_seen normalized sql_probe

    command="$1"
    normalized="$(strip_command_wrappers "$command")"

    set -f
    # shellcheck disable=SC2046
    set -- $(printf '%s' "$normalized" | xargs -n1 printf '%s\n')
    set +f
    first_token="${1:-}"
    shift 2>/dev/null || true

    if command_uses_rm "$first_token"; then
        target_seen=0
        for token in "$@"; do
            case "$(strip_trailing_separators "$(strip_wrapping_quotes "$token")")" in
                --|-[[:alnum:]-]*)
                    continue
                    ;;
            esac

            if is_destructive_rm_target "$token"; then
                target_seen=1
                break
            fi
        done

        if [ "$target_seen" -eq 1 ]; then
            printf 'Blocked: destructive rm detected. Command: %s\n' "$command" >&2
            return 2
        fi
    fi

    if is_sql_client_command "$first_token" || command_pipes_into_sql_client "$command"; then
        sql_probe="$(normalize_sql_text "$command")"
        case "$sql_probe" in
            *DROP[[:space:][:punct:]]TABLE*|*DROP[[:space:][:punct:]]DATABASE*)
                printf 'Blocked: destructive SQL command detected.\n' >&2
                return 2
                ;;
        esac
    fi

    case "$first_token" in
        cat|*/cat|less|*/less|more|*/more|head|*/head|tail|*/tail|grep|*/grep|source|*/source|sed|*/sed|.|*/.)
            env_ref="$(command_contains_sensitive_env_read "$@")" || true
            if [ -n "$env_ref" ]; then
                printf 'Blocked: reading sensitive env file via shell: %s\n' "$env_ref" >&2
                return 2
            fi
            ;;
    esac

    case "$command" in
        *"sudo "*)
            printf 'Warning: sudo usage detected. Ensure this is intentional: %s\n' "$command" >&2
            ;;
    esac

    case "$command" in
        *"| bash"*|*"| sh"*|*"|bash"*|*"|sh"*)
            printf 'Warning: pipe-to-shell detected (supply chain risk): %s\n' "$command" >&2
            ;;
    esac

    return 0
}
