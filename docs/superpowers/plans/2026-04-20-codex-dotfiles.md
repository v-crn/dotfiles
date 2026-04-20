# Codex Dotfiles Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Manage `~/.codex/` core files (AGENTS.md, config.toml, notify hook) via chezmoi, sharing notification infrastructure with Claude Code hooks.

**Architecture:** Move notification library from `~/.claude/hooks/lib/` to `~/.agents/hooks/lib/`; claude hooks source it directly (no shim layer needed — the lib directory is removed entirely). Codex config.toml is regenerated on every `chezmoi apply` by an awk-based run script that strips managed sections and appends desired TOML while preserving `[projects.*]` and other env-specific sections. `~/.codex/AGENTS.md` is generated as a flat file via chezmoi template embedding shared rule files (codex does not support `@path` includes).

**Tech Stack:** chezmoi (dotfiles management), POSIX sh/bash, awk

---

## Prerequisites

chezmoi's default source is `~/.local/share/chezmoi`. This repo is a separate source
that must be specified explicitly. All `chezmoi` commands in this plan use the helper:

```bash
alias cm='chezmoi --source "$(git -C /workspace/dotfiles rev-parse --show-toplevel)/home"'
```

Set this alias before starting, or substitute `chezmoi --source /workspace/dotfiles/home`
for every `chezmoi` call.

---

## File Map

### New files

| Source path | Deployed path | Purpose |
| --- | --- | --- |
| `home/dot_agents/hooks/lib/executable_platform.sh` | `~/.agents/hooks/lib/platform.sh` | Platform detection (moved from claude) |
| `home/dot_agents/hooks/lib/executable_notify.sh` | `~/.agents/hooks/lib/notify.sh` | Notification library (moved from claude) |
| `home/dot_codex/AGENTS.md.tmpl` | `~/.codex/AGENTS.md` | Flat codex global instructions |
| `home/dot_codex/hooks/executable_notify.sh` | `~/.codex/hooks/notify.sh` | Post-turn notification hook |
| `home/dot_codex/run_apply-codex-config.sh` | *(run script — executed by chezmoi, not deployed)* | config.toml generator |

### Modified files

| Source path | Change |
| --- | --- |
| `home/dot_claude/hooks/executable_notification.sh` | Source `~/.agents/hooks/lib/notify.sh` directly |
| `home/dot_claude/hooks/executable_stop.sh` | Source `~/.agents/hooks/lib/notify.sh` directly |

### Deleted files

| Source path | Deployed path removed |
| --- | --- |
| `home/dot_claude/hooks/lib/executable_notify.sh` | `~/.claude/hooks/lib/notify.sh` |
| `home/dot_claude/hooks/lib/executable_platform.sh` | `~/.claude/hooks/lib/platform.sh` |

---

### Task 1: Move notification library to `~/.agents/hooks/lib/`

**Files:**

- Create: `home/dot_agents/hooks/lib/executable_platform.sh`
- Create: `home/dot_agents/hooks/lib/executable_notify.sh`
- Modify: `home/dot_claude/hooks/executable_notification.sh`
- Modify: `home/dot_claude/hooks/executable_stop.sh`
- Delete: `home/dot_claude/hooks/lib/executable_notify.sh`
- Delete: `home/dot_claude/hooks/lib/executable_platform.sh`

- [ ] **Step 1: Create `home/dot_agents/hooks/lib/executable_platform.sh`**

```bash
#!/bin/bash
# Detect the current platform and export PLATFORM.
# Values: macos | wsl | linux | unknown
# Source this file: . platform.sh
# After sourcing, $PLATFORM is set and exported.

_detect_platform() {
    local kernel
    kernel="$(uname -s 2>/dev/null)"
    if [ "$kernel" = "Darwin" ]; then
        echo "macos"
    elif [ -n "${WSL_DISTRO_NAME:-}" ]; then
        echo "wsl"
    elif [ "$kernel" = "Linux" ]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

PLATFORM="$(_detect_platform)"
export PLATFORM
```

- [ ] **Step 2: Create `home/dot_agents/hooks/lib/executable_notify.sh`**

```bash
#!/bin/bash
# Shared notification library for agent hooks.
# Usage: source this file, then call send_notification TITLE MESSAGE.

NOTIFY_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$NOTIFY_LIB_DIR/platform.sh"

# send_notification TITLE MESSAGE
# Sends a desktop notification using the platform-appropriate command.
# Falls back to stderr when no notification command is available.
send_notification() {
    local title="$1"
    local message="$2"

    case "$PLATFORM" in
        macos)
            osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null
            ;;
        wsl|linux)
            if command -v notify-send >/dev/null 2>&1; then
                notify-send "$title" "$message"
            else
                printf '[NOTICE] %s: %s\n' "$title" "$message" >&2
            fi
            ;;
        *)
            printf '[NOTICE] %s: %s\n' "$title" "$message" >&2
            ;;
    esac
}
```

- [ ] **Step 3: Update `home/dot_claude/hooks/executable_notification.sh`**

```bash
#!/bin/bash
# Notification event hook for Claude Code.
# Fires when Claude needs attention (permission prompt, idle, etc.).
# shellcheck disable=SC1091
. ~/.agents/hooks/lib/notify.sh

cat > /dev/null

send_notification "Claude Code" "Needs your attention"
```

- [ ] **Step 4: Update `home/dot_claude/hooks/executable_stop.sh`**

Replace only the `HOOK_DIR` setup and `. "$HOOK_DIR/lib/notify.sh"` preamble with the direct source. Full file:

```bash
#!/bin/bash
# Stop event hook for Claude Code.
# Sends a completion notification after responses that took >= 10 seconds.
# Skips fast responses to avoid noise during short back-and-forth exchanges.
# shellcheck disable=SC1091
. ~/.agents/hooks/lib/notify.sh

INPUT="$(cat)"

# Guard: stop_hook_active=true means we're already in a stop hook loop — exit early
if [ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ]; then
    exit 0
fi

SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // empty')"
if [ -z "$SESSION_ID" ]; then
    exit 0
fi
MARKER_FILE="${TMPDIR:-/tmp}/claude-last-stop-${SESSION_ID}"

NOW="$(date +%s)"

# First call for this session: write marker, skip notification
if [ ! -f "$MARKER_FILE" ]; then
    printf '%s\n' "$NOW" > "$MARKER_FILE"
    exit 0
fi

LAST_STOP="$(cat "$MARKER_FILE")"
ELAPSED=$(( NOW - LAST_STOP ))

# Update marker timestamp for next call
printf '%s\n' "$NOW" > "$MARKER_FILE"

# Notify only if Claude was working for >= 10 seconds
if [ "$ELAPSED" -ge 10 ]; then
    send_notification "Claude Code" "Finished"
fi

exit 0
```

- [ ] **Step 5: Delete `home/dot_claude/hooks/lib/executable_notify.sh` and `executable_platform.sh`**

```bash
git rm home/dot_claude/hooks/lib/executable_notify.sh
git rm home/dot_claude/hooks/lib/executable_platform.sh
```

chezmoi will remove the deployed `~/.claude/hooks/lib/` files on the next apply.

- [ ] **Step 6: Apply and verify Claude notifications still work**

```bash
cm apply --dry-run 2>&1 | head -30
cm apply
```

Verify the notification chain works end-to-end:

```bash
bash -c '. ~/.agents/hooks/lib/notify.sh && send_notification "Test" "Shared lib works"'
bash -c '. ~/.claude/hooks/lib/notify.sh 2>/dev/null || . ~/.agents/hooks/lib/notify.sh && send_notification "Claude" "Hook works"'
```

Actually, since `~/.claude/hooks/lib/` is now removed, test via the actual hook scripts:

```bash
echo '{}' | bash ~/.claude/hooks/notification.sh
```

Expected: notification popup or `[NOTICE] Claude Code: Needs your attention` on stderr.

- [ ] **Step 7: Commit**

```bash
git add home/dot_agents/hooks/ home/dot_claude/hooks/
git commit -m "refactor: move notification library to ~/.agents/hooks/lib/, remove claude lib dir"
```

---

### Task 2: Create `home/dot_codex/AGENTS.md.tmpl`

Codex does not support `@path` include directives, so the deployed `~/.codex/AGENTS.md`
must be a flat file with all rule content embedded. A chezmoi template using `include`
embeds source files at apply time.

> **Implementation note:** chezmoi's `include` function reads files relative to the
> chezmoi source directory. Verify the path prefix by running
> `cm data | grep sourceDir` if apply fails. The paths below assume the source
> directory is `home/` (i.e., `include "dot_agents/..."` maps to `home/dot_agents/...`).

**Files:**

- Create: `home/dot_codex/AGENTS.md.tmpl`

- [ ] **Step 1: Create template**

```text
# AGENTS.md

{{ include "dot_agents/rules/common/language-policy.md" }}

{{ include "dot_agents/rules/common/markdown-linting.md" }}

{{ include "dot_agents/rules/common/preferred-tools.md" }}

{{ include "dot_agents/rules/common/privacy-policy.md" }}

{{ include "dot_agents/rules/common/security.md" }}
{{- if eq .chezmoi.os "linux" }}
{{-   if contains "microsoft" .chezmoi.kernel.osrelease }}

{{ include "dot_agents/rules/wsl/coding-style.md" }}
{{-   end }}
{{- end }}
```

- [ ] **Step 2: Apply and inspect the generated file**

```bash
cm apply --dry-run ~/.codex/AGENTS.md 2>&1
cm apply ~/.codex/AGENTS.md
```

Verify it contains rule content with no `@` directives:

```bash
grep -c '^#' ~/.codex/AGENTS.md
grep -n '^@' ~/.codex/AGENTS.md && echo "FAIL: @ found" || echo "OK: no @ directives"
```

Expected: several `#` headings, `OK: no @ directives`.

- [ ] **Step 3: Commit**

```bash
git add home/dot_codex/AGENTS.md.tmpl
git commit -m "feat: add ~/.codex/AGENTS.md as chezmoi template embedding shared rules"
```

---

### Task 3: Create `home/dot_codex/hooks/executable_notify.sh`

**Files:**

- Create: `home/dot_codex/hooks/executable_notify.sh`

- [ ] **Step 1: Create notify hook**

```bash
#!/bin/bash
# Post-turn notification hook for OpenAI Codex CLI.
# Referenced in config.toml: notify = ["~/.codex/hooks/notify.sh"]
# shellcheck disable=SC1091
. ~/.agents/hooks/lib/notify.sh

send_notification "Codex" "Finished"
```

- [ ] **Step 2: Apply and verify the hook is executable**

```bash
cm apply ~/.codex/hooks/notify.sh
ls -la ~/.codex/hooks/notify.sh
```

Expected: file with execute bit set (`-rwxr-xr-x` or similar).

- [ ] **Step 3: Verify the hook runs without error**

```bash
~/.codex/hooks/notify.sh
```

Expected: notification popup, or `[NOTICE] Codex: Finished` on stderr.

- [ ] **Step 4: Commit**

```bash
git add home/dot_codex/hooks/
git commit -m "feat: add ~/.codex/hooks/notify.sh for post-turn notifications"
```

---

### Task 4: Create `home/dot_codex/run_apply-codex-config.sh`

The `run_` prefix tells chezmoi to execute this script on every `chezmoi apply`.
The script is **not deployed** as a file — it runs as part of the apply process and
regenerates `~/.codex/config.toml`.

**Awk strategy:**

- *Managed top-level keys* (`model`, `approval_policy`, etc.) are single-line `key = value`
  entries. The awk key pattern removes them regardless of their position in the file.
- *Managed sections* (`[tui]`, `[features]`, etc.) are section headers plus all lines
  until the next header. The awk section pattern enters skip mode on the header line.
- *Preserved sections* (`[projects.*]`, `[auth.*]`, `[notice.*]`) are never matched
  by either pattern and pass through unchanged.
- Multi-line TOML arrays for managed keys (e.g., `notify = [\n...\n]`) are **not**
  supported by the awk remover. The DESIRED block always uses single-line form to avoid
  this edge case.

**Files:**

- Create: `home/dot_codex/run_apply-codex-config.sh`

- [ ] **Step 1: Create script**

```bash
#!/bin/sh
# Generate ~/.codex/config.toml by merging managed settings into any existing file.
# Run via chezmoi on every apply (run_ prefix). Not deployed as a file.
#
# Managed top-level keys (removed then rewritten):
#   model, model_reasoning_effort, approval_policy, sandbox_mode, personality, notify
#
# Managed sections (removed then rewritten):
#   [tui], [features], [memories], [profiles.*]
#
# Preserved (never touched):
#   [projects.*]  per-environment trust levels
#   [auth.*]      authentication credentials
#   [notice.*]    per-install dismissed-warning state flags
#   Any unknown future sections

# -----------------------------------------------------------------------
# Desired settings (edit this section to update config)
# -----------------------------------------------------------------------
DESIRED=$(cat <<'TOML'
model = "o4-mini"
model_reasoning_effort = "medium"
approval_policy = "on-request"
sandbox_mode = "workspace-write"
personality = "Be concise and precise. Prefer minimal, focused changes. Follow existing code conventions."
notify = ["~/.codex/hooks/notify.sh"]

[tui]
status_line = ["model-with-reasoning", "current-dir", "git-branch", "context-used", "context-window-size"]
notifications = true
notification_condition = "always"

[features]
memories = true

[profiles.conservative]
approval_policy = "on-request"
sandbox_mode = "read-only"

[profiles.development]
approval_policy = "on-request"
sandbox_mode = "workspace-write"
TOML
)

# -----------------------------------------------------------------------
# Merge logic
# -----------------------------------------------------------------------
TARGET="$HOME/.codex/config.toml"

if ! command -v awk >/dev/null 2>&1; then
    printf 'Warning: awk not found. Skipping codex config merge.\n' >&2
    exit 0
fi

# New install: write desired as-is
if [ ! -f "$TARGET" ]; then
    mkdir -p "$(dirname "$TARGET")"
    TMP=$(mktemp "${TARGET}.tmp.XXXXXX")
    if ! { printf '%s\n' "$DESIRED" > "$TMP" && mv "$TMP" "$TARGET"; }; then
        rm -f "$TMP"; exit 1
    fi
    exit 0
fi

# Backup existing config before every apply
cp "$TARGET" "${TARGET}.bak"

# Strip managed top-level keys and sections, preserving everything else
MANAGED_KEYS='model|model_reasoning_effort|approval_policy|sandbox_mode|personality|notify'
MANAGED_SECTS='tui|features|memories|profiles'

TMP=$(mktemp "${TARGET}.tmp.XXXXXX")
awk \
    -v keys="^(${MANAGED_KEYS})[[:space:]]*=" \
    -v sects="^\\[(${MANAGED_SECTS})(\\.|\\])" \
    '
    $0 ~ sects               { skip=1; next }
    /^\[/ && !($0 ~ sects)   { skip=0 }
    skip                     { next }
    $0 ~ keys                { next }
    { print }
    ' "$TARGET" > "$TMP"

# Guard: abort if awk produced empty output for a non-empty input
if [ ! -s "$TMP" ] && [ -s "$TARGET" ]; then
    printf 'Error: awk produced empty output. Aborting merge.\n' >&2
    rm -f "$TMP"
    exit 1
fi

# Append desired managed settings
printf '%s\n' "$DESIRED" >> "$TMP"

mv "$TMP" "$TARGET"
```

- [ ] **Step 2: Apply (chezmoi executes the run script) and inspect the result**

```bash
cm apply
cat ~/.codex/config.toml
```

Expected — `[projects.*]` preserved, desired settings appended:

```toml
[projects."/workspace/dotfiles"]
trust_level = "trusted"

model = "o4-mini"
model_reasoning_effort = "medium"
approval_policy = "on-request"
sandbox_mode = "workspace-write"
personality = "Be concise and precise. ..."
notify = ["~/.codex/hooks/notify.sh"]

[tui]
status_line = [...]
notifications = true
notification_condition = "always"

[features]
memories = true

[profiles.conservative]
approval_policy = "on-request"
sandbox_mode = "read-only"

[profiles.development]
approval_policy = "on-request"
sandbox_mode = "workspace-write"
```

- [ ] **Step 3: Verify backup was created**

```bash
ls -la ~/.codex/config.toml.bak
diff ~/.codex/config.toml.bak ~/.codex/config.toml | head -20
```

Expected: backup exists; diff shows removed old managed settings and new desired block.

- [ ] **Step 4: Idempotency check — run apply again**

```bash
cm apply
diff ~/.codex/config.toml.bak ~/.codex/config.toml
```

Expected: empty diff (second apply produces identical output; `.bak` is updated to
post-first-apply state before the second run, so diff is empty when idempotent).

- [ ] **Step 5: Commit**

```bash
git add home/dot_codex/run_apply-codex-config.sh
git commit -m "feat: add run_apply-codex-config.sh for managed config.toml generation"
```

---

### Task 5: End-to-end verification

- [ ] **Step 1: Full chezmoi apply**

```bash
cm apply
```

- [ ] **Step 2: Verify deployed file tree**

```bash
ls -la ~/.codex/
ls -la ~/.agents/hooks/lib/
ls -la ~/.claude/hooks/
```

Expected:

```text
~/.codex/
  AGENTS.md                 flat markdown, no @ directives
  hooks/notify.sh           executable
  config.toml               desired sections present

~/.agents/hooks/lib/
  notify.sh                 full implementation, executable
  platform.sh               full implementation, executable

~/.claude/hooks/
  notification.sh           sources ~/.agents/hooks/lib/notify.sh directly
  stop.sh                   sources ~/.agents/hooks/lib/notify.sh directly
  pre-tool-use.sh           unchanged
  (lib/ directory gone)
```

- [ ] **Step 3: Smoke-test all notification paths**

```bash
echo '{}' | bash ~/.claude/hooks/notification.sh
bash ~/.codex/hooks/notify.sh
```

Expected: both produce a notification popup or `[NOTICE]` stderr output without error.

- [ ] **Step 4: Verify codex AGENTS.md has no @ directives**

```bash
grep -n '^@' ~/.codex/AGENTS.md && echo "FAIL: @ directives found" || echo "OK"
```

Expected: `OK`

- [ ] **Step 5: Verify config.toml preserved [projects.*]**

```bash
grep -A1 '^\[projects' ~/.codex/config.toml
```

Expected: `[projects."/workspace/dotfiles"]` followed by `trust_level = "trusted"`.
