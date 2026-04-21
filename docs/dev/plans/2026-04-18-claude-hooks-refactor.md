# Claude Hooks Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consolidate redundant PreToolUse hook entries in settings.json and simplify `.env` detection helpers in pre-tool-use.sh, with no behavior changes.

**Architecture:** Three independent edits to existing files. No new files. Existing bats tests are the verification gate — they must all pass after each task without modification.

**Tech Stack:** bash, jq, bats, chezmoi

**Spec:** `docs/superpowers/specs/2026-04-18-claude-hooks-refactor-design.md`

---

## File Map

| Action | Path |
| --- | --- |
| Modify | `home/dot_claude/run_apply-claude-settings.sh` |
| Modify | `home/dot_claude/hooks/executable_pre-tool-use.sh` |
| Modify | `docs/superpowers/specs/2026-04-18-claude-code-hooks-design.md` |

---

## Task 1: Consolidate PreToolUse entries in settings.json

**Files:**

- Modify: `home/dot_claude/run_apply-claude-settings.sh` (lines 106–115)

- [ ] **Step 1: Verify the current state**

```bash
grep -A 12 '"PreToolUse"' home/dot_claude/run_apply-claude-settings.sh
```

Expected output — two entries pointing to the same script:

```text
        "PreToolUse": [
            {
                "matcher": "Bash",
                "hooks": [{"type": "command", "command": "~/.claude/hooks/pre-tool-use.sh"}]
            },
            {
                "matcher": "Read|Edit|Write",
                "hooks": [{"type": "command", "command": "~/.claude/hooks/pre-tool-use.sh"}]
            }
        ],
```

- [ ] **Step 2: Replace the two-entry block with one combined entry**

In `home/dot_claude/run_apply-claude-settings.sh`, replace:

```json
        "PreToolUse": [
            {
                "matcher": "Bash",
                "hooks": [{"type": "command", "command": "~/.claude/hooks/pre-tool-use.sh"}]
            },
            {
                "matcher": "Read|Edit|Write",
                "hooks": [{"type": "command", "command": "~/.claude/hooks/pre-tool-use.sh"}]
            }
        ],
```

With:

```json
        "PreToolUse": [
            {
                "matcher": "Bash|Read|Edit|Write",
                "hooks": [{"type": "command", "command": "~/.claude/hooks/pre-tool-use.sh"}]
            }
        ],
```

- [ ] **Step 3: Run the settings tests**

```bash
cd /workspace/dotfiles && bats tests/test_claude_settings.bats
```

Expected: all tests pass. The PreToolUse length check (`>= 2`) still holds because the fixture adds one existing entry, giving a total of 2.

- [ ] **Step 4: Commit**

```bash
git add home/dot_claude/run_apply-claude-settings.sh
git commit -m "refactor: consolidate PreToolUse hook entries into single matcher"
```

---

## Task 2: Merge `.env` detection helpers in pre-tool-use.sh

**Files:**

- Modify: `home/dot_claude/hooks/executable_pre-tool-use.sh`

The goal is to replace two functions (`is_env_file` + `is_safe_env_file`) with one (`is_sensitive_env_file`) and update both call sites. Behavior is identical — no test changes needed.

- [ ] **Step 1: Run the hooks tests to confirm baseline**

```bash
cd /workspace/dotfiles && bats tests/test_hooks.bats
```

Expected: all tests pass before any change.

- [ ] **Step 2: Replace the helper functions**

In `home/dot_claude/hooks/executable_pre-tool-use.sh`, replace the entire `.env file helpers` section (the two functions `is_safe_env_file` and `is_env_file`):

```bash
# ---------------------------------------------------------------------------
# .env file helpers
# ---------------------------------------------------------------------------

# is_safe_env_file PATH_OR_BASENAME
# Returns 0 (safe/allow) if any dot-separated segment is a safe keyword.
# Returns 1 (unsafe/block) otherwise.
is_safe_env_file() {
    local base
    base="$(basename "$1")"

    # Must start with .env to be relevant
    case "$base" in
        .env*) ;;
        *) return 1 ;;
    esac

    # Strip leading dot, split by '.', check each segment
    local stripped="${base#.}"
    local old_IFS="$IFS"
    IFS='.'
    # shellcheck disable=SC2086
    set -- $stripped
    IFS="$old_IFS"
    for segment; do
        case "$segment" in
            example|template|sample|default|dist|schema)
                return 0  # safe keyword found
                ;;
        esac
    done
    return 1  # no safe keyword → block
}

# is_env_file PATH_OR_BASENAME
# Returns 0 if the basename is exactly .env or starts with .env.
is_env_file() {
    local base
    base="$(basename "$1")"
    case "$base" in
        .env | .env.*) return 0 ;;
        *) return 1 ;;
    esac
}
```

With:

```bash
# ---------------------------------------------------------------------------
# .env file helpers
# ---------------------------------------------------------------------------

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
        .env | .env.*) ;;
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

- [ ] **Step 3: Update the Read/Edit/Write call site**

In the same file, find the file-based tools handler and replace the condition:

```bash
        if [ -n "$FILE_PATH" ] && is_env_file "$FILE_PATH" && ! is_safe_env_file "$FILE_PATH"; then
```

With:

```bash
        if [ -n "$FILE_PATH" ] && is_sensitive_env_file "$FILE_PATH"; then
```

- [ ] **Step 4: Update the Bash call site**

Find the `.env via shell commands` block and replace the condition:

```bash
            if [ -n "$ENV_REF" ] && ! is_safe_env_file "$ENV_REF"; then
```

With:

```bash
            if [ -n "$ENV_REF" ] && is_sensitive_env_file "$ENV_REF"; then
```

- [ ] **Step 5: Run the hooks tests**

```bash
cd /workspace/dotfiles && bats tests/test_hooks.bats
```

Expected: all tests pass. Pay particular attention to:

- `pre-tool-use.sh: blocks Read of .env` → status 2
- `pre-tool-use.sh: allows Read of .env.example` → status 0
- `pre-tool-use.sh: allows Read of .envrc (direnv config)` → status 0
- `pre-tool-use.sh: blocks cat .env` → status 2
- `pre-tool-use.sh: allows cat .env.example` → status 0

- [ ] **Step 6: Run the full test suite**

```bash
cd /workspace/dotfiles && bats tests/test_hooks.bats && bats tests/test_claude_settings.bats
```

Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
git add home/dot_claude/hooks/executable_pre-tool-use.sh
git commit -m "refactor: merge .env helpers into is_sensitive_env_file"
```

---

## Task 3: Fix hooks merge strategy in original design doc

**Files:**

- Modify: `docs/superpowers/specs/2026-04-18-claude-code-hooks-design.md`

- [ ] **Step 1: Locate the inaccurate paragraph**

```bash
grep -n "overwrite" docs/superpowers/specs/2026-04-18-claude-code-hooks-design.md
```

Expected: one match in the "settings.json Integration" section near the end of the file.

- [ ] **Step 2: Replace the merge strategy description**

Find and replace:

```text
The merge strategy for `hooks` in `run_apply-claude-settings.sh`: **overwrite** (replace the entire `hooks` object from `DESIRED`). This differs from the array-union approach used for `permissions.allow/deny`, because hook order and deduplication are managed at the script level, not via JSON merging.
```

With:

```text
The merge strategy for `hooks` in `run_apply-claude-settings.sh`: **union per event** — for each event key present in `DESIRED` (e.g., `PreToolUse`, `Notification`, `Stop`), its hook array is unioned (via `unique`) into the existing array for that event; event keys not present in `DESIRED` are preserved unchanged. This is consistent with the array-union approach used for `permissions.allow/deny`.
```

- [ ] **Step 3: Run markdownlint to verify no lint errors**

```bash
markdownlint-cli2 "docs/superpowers/specs/2026-04-18-claude-code-hooks-design.md"
```

Expected: `Summary: 0 error(s)`

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/specs/2026-04-18-claude-code-hooks-design.md
git commit -m "docs: fix hooks merge strategy description (overwrite → union per event)"
```

---

## Self-Review Notes

**Spec coverage:**

- settings.json consolidation (2 → 1 entry) ✓ Task 1
- `is_sensitive_env_file` replacing two functions ✓ Task 2
- Both call sites updated ✓ Task 2 Steps 3–4
- `.envrc` exclusion preserved via `.env | .env.*` pattern ✓ Task 2 Step 2
- Design doc merge strategy fix ✓ Task 3
- Test verification after each change ✓ All tasks

**No placeholders:** All code blocks show complete, runnable content.

**Type consistency:** `is_sensitive_env_file` is defined once (Task 2 Step 2) and referenced in Task 2 Steps 3–4. No drift.
