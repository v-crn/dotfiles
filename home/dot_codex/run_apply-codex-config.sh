#!/bin/sh
# Generate ~/.codex/config.toml by merging managed settings into any existing file.
# Run via chezmoi on every apply (run_ prefix). Not deployed as a file.
#
# Managed top-level keys (removed then rewritten):
#   model_reasoning_effort, approval_policy, sandbox_mode,
#   personality, model_context_window, model_auto_compact_token_limit,
#   tool_output_token_limit, background_terminal_max_timeout,
#   log_dir, sqlite_home, notify
#
# Managed sections (removed then rewritten):
#   [tui], [features], [profiles.*]
#
# Preserved (never touched):
#   model
#   [projects.*]  per-environment trust levels
#   [auth.*]      authentication credentials
#   [notice.*]    per-install dismissed-warning state flags
#   Any unknown future sections

# -----------------------------------------------------------------------
# Desired settings (edit this section to update config)
# -----------------------------------------------------------------------
DESIRED=$(cat <<'TOML'
# Curated from the official Codex sample config:
# https://developers.openai.com/codex/config-sample

# Service tier selection. Leave commented unless a specific tier is needed.
# service_tier = "flex"

# Reasoning effort: minimal | low | medium | high | xhigh
model_reasoning_effort = "medium"

# When to ask for command approval:
# - untrusted: only known-safe read-only commands auto-run; others prompt
# - on-request: model decides when to ask (default)
# - never: never prompt (risky)
# - { granular = { ... } }: allow or auto-reject selected prompt categories
approval_policy = "on-request"

# Filesystem/network sandbox policy for tool calls:
# - read-only (default)
# - workspace-write
# - danger-full-access (no sandbox; extremely risky)
sandbox_mode = "workspace-write"

# Communication style for supported models. Allowed values: none | friendly | pragmatic
personality = "pragmatic"

# Optional manual model metadata. When unset, Codex uses model or preset defaults.
# model_context_window = 128000       # tokens; default: auto for model
# model_auto_compact_token_limit = 64000  # tokens; unset uses model defaults
# tool_output_token_limit = 12000     # tokens stored per tool output
# background_terminal_max_timeout = 300000
# log_dir = "/absolute/path/to/codex-logs" # directory for Codex logs; default: "$CODEX_HOME/log"
# sqlite_home = "/absolute/path/to/codex-state" # optional SQLite-backed runtime state directory

# External notifier program (argv array). When unset: disabled.
# notify = ["notify-send", "Codex"]

[tui]
status_line = [
    "model-with-reasoning",
    "git-branch",
    "context-used",
    "context-window-size",
    "used-tokens",
    "five-hour-limit",
    "weekly-limit",
]

# Desktop notifications from the TUI: boolean or filtered list. Default: true
# Examples: false | ["agent-turn-complete", "approval-requested"]
notifications = true

# When notifications fire: unfocused (default) | always
notification_condition = "always"

[features]
memories = true
hooks = true

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
if ! cp "$TARGET" "${TARGET}.bak"; then
    printf 'Error: failed to create backup at %s.bak. Aborting merge.\n' "$TARGET" >&2
    exit 1
fi

# Strip managed top-level keys and sections, preserving everything else.
MANAGED_KEYS='model_reasoning_effort|approval_policy|sandbox_mode|personality|model_context_window|model_auto_compact_token_limit|tool_output_token_limit|background_terminal_max_timeout|log_dir|sqlite_home|notify'
MANAGED_SECTS='tui|features|profiles'

TMP=$(mktemp "${TARGET}.tmp.XXXXXX")
TMP2=$(mktemp "${TARGET}.tmp2.XXXXXX")
if ! awk \
    -v keys="^(${MANAGED_KEYS})[[:space:]]*=" \
    -v sects="^[[](${MANAGED_SECTS})([.]|[]])" \
    '
    $0 == "# Curated from the official Codex sample config:" {
        in_managed_preamble = 1
        next
    }

    /^\[/ {
        in_managed_preamble = 0
        if ($0 ~ sects) {
            skip_section = 1
            next
        }
        skip_section = 0
    }

    skip_section { next }

    in_managed_preamble {
        if ($0 ~ /^[[:space:]]*#/ || $0 ~ /^[[:space:]]*$/) {
            next
        }

        if ($0 ~ keys) {
            next
        }

        print
        next
    }

    $0 ~ keys { next }

    { print }
    ' "$TARGET" > "$TMP2"; then
    printf 'Error: awk failed. Aborting merge.\n' >&2
    rm -f "$TMP" "$TMP2"
    exit 1
fi

# Strip trailing blank lines from preserved content, then add exactly one blank
# line separator before the desired block to ensure idempotency.
awk 'NF { buf = buf $0 "\n" }
     END { if (buf != "") printf "%s", buf }' "$TMP2" > "$TMP"
rm -f "$TMP2"

if [ -s "$TMP" ]; then
    printf '\n' >> "$TMP"
fi

# Append desired managed settings
printf '%s\n' "$DESIRED" >> "$TMP"

mv "$TMP" "$TARGET"
