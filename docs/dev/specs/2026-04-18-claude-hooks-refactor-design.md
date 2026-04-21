# Claude Hooks Refactor Design

**Date:** 2026-04-18
**Branch:** dev
**Scope:** Refactor PreToolUse hooks configuration and `pre-tool-use.sh` helper functions

## Overview

Two targeted improvements to the existing Claude Code hooks setup:

1. **settings.json:** Consolidate two `PreToolUse` entries pointing to the same script into one entry using a combined regex matcher.
2. **pre-tool-use.sh:** Replace the two-function `.env` detection helpers with a single, clearly named function.
3. **Design doc fix:** Correct the hooks merge strategy description in the original design document.

No behavior changes. No new files. All existing tests continue to pass without modification.

---

## Problem Statement

### 1. Redundant PreToolUse entries in settings.json

The current DESIRED block in `run_apply-claude-settings.sh` registers two `PreToolUse` entries that both invoke the same script:

```json
"PreToolUse": [
    { "matcher": "Bash",            "hooks": [{ "command": "~/.claude/hooks/pre-tool-use.sh" }] },
    { "matcher": "Read|Edit|Write", "hooks": [{ "command": "~/.claude/hooks/pre-tool-use.sh" }] }
]
```

The script already dispatches internally on `tool_name`, so the two-entry configuration adds no value and creates a maintenance smell.

**Verified:** Claude Code's `matcher` field accepts regular expressions. The pattern `"Write|Edit"` appears in official documentation as a valid example.

### 2. Awkward two-function `.env` detection in `pre-tool-use.sh`

The script uses two functions and a double-negative condition to decide whether to block a file:

```bash
is_env_file "$FILE_PATH" && ! is_safe_env_file "$FILE_PATH"
```

`is_env_file` exists only to guard against `! is_safe_env_file` returning true for non-`.env` files. This is an implementation detail leaking into the call site.

### 3. Design doc inaccuracy

`docs/superpowers/specs/2026-04-18-claude-code-hooks-design.md` describes the hooks merge strategy as "overwrite," but the actual implementation in `run_apply-claude-settings.sh` uses "union per event." The doc needs updating.

---

## Changes

### `run_apply-claude-settings.sh`

Merge the two `PreToolUse` entries into one using the `|` regex OR operator:

```json
"PreToolUse": [
    {
        "matcher": "Bash|Read|Edit|Write",
        "hooks": [{ "type": "command", "command": "~/.claude/hooks/pre-tool-use.sh" }]
    }
]
```

### `home/dot_claude/hooks/executable_pre-tool-use.sh`

Replace `is_env_file` + `is_safe_env_file` with a single `is_sensitive_env_file` function.

**Semantics (unchanged):** Returns 0 (block) when the file basename starts with `.env` and contains no safe-keyword segment. Returns 1 (allow) otherwise.

```bash
# Before
is_env_file "$FILE_PATH" && ! is_safe_env_file "$FILE_PATH"

# After
is_sensitive_env_file "$FILE_PATH"
```

Function definition:

```bash
# is_sensitive_env_file PATH_OR_BASENAME
# Returns 0 (block) if the file is a sensitive .env file.
# Matches exactly ".env" or ".env.<something>" (dot-separated).
# Files like ".envrc" (no dot separator) are NOT matched and pass through.
# A matched file is sensitive when none of its dot-separated segments
# is a safe keyword: example template sample default dist schema
is_sensitive_env_file() {
    local base
    base="$(basename "$1")"
    case "$base" in
        .env | .env.*) ;;   # require exact ".env" or ".env." prefix
        *) return 1 ;;
    esac
    local stripped="${base#.}"
    local old_IFS="$IFS"
    IFS='.'
    # shellcheck disable=SC2086
    set -- $stripped
    IFS="$old_IFS"
    for segment; do
        case "$segment" in
            example|template|sample|default|dist|schema)
                return 1  # safe keyword found — allow
                ;;
        esac
    done
    return 0  # no safe keyword — block
}
```

Call sites:

```bash
# File-based tools (Read/Edit/Write)
if is_sensitive_env_file "$FILE_PATH"; then
    printf 'Blocked: ...' >&2; exit 2
fi

# Bash tool (.env via shell commands)
if [ -n "$ENV_REF" ] && is_sensitive_env_file "$ENV_REF"; then
    printf 'Blocked: ...' >&2; exit 2
fi
```

### `docs/superpowers/specs/2026-04-18-claude-code-hooks-design.md`

In the "settings.json Integration" section, update the merge strategy description:

```text
# Before
The merge strategy for hooks in run_apply-claude-settings.sh: **overwrite**
(replace the entire hooks object from DESIRED).

# After
The merge strategy for hooks in run_apply-claude-settings.sh:
**union per event** — for each event key present in DESIRED, its hook array
is unioned (via unique) into the existing array; event keys not in DESIRED
are preserved unchanged.
```

---

## Impact on Tests

| File | Change required |
| --- | --- |
| `tests/test_hooks.bats` | None — `run_hook` calls the script directly, unaffected |
| `tests/test_claude_settings.bats` | None — the PreToolUse length check uses `>= 2`; after merge the count is still 2 (1 desired + 1 existing fixture entry) |

---

## Non-Goals

- No file splitting of `pre-tool-use.sh`
- No new lib/ modules
- No changes to notification, stop, platform, or notify scripts
- No new hook event types
