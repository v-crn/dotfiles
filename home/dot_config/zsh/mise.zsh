if command -v mise &>/dev/null; then
    # Use shims-only activation to avoid per-prompt hook-env side effects from tools
    # that inject shell integration state during zsh startup.
    eval "$(mise activate zsh --shims)"
fi
