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
TMP2=$(mktemp "${TARGET}.tmp2.XXXXXX")
if ! awk \
    -v keys="^(${MANAGED_KEYS})[[:space:]]*=" \
    -v sects="^\\[(${MANAGED_SECTS})(\\.|\\])" \
    '
    $0 ~ sects               { skip=1; next }
    /^\[/ && !($0 ~ sects)   { skip=0 }
    skip                     { next }
    $0 ~ keys                { next }
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
printf '\n' >> "$TMP"

# Append desired managed settings
printf '%s\n' "$DESIRED" >> "$TMP"

mv "$TMP" "$TARGET"
