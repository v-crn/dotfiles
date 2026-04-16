# Preferred Tools

## 1. Tool Selection Priority

1. Project Standards: Use project-defined scripts (e.g., `make`, `just`, `npm run`) to ensure consistency.
2. Specialized Skills: Use agent-specific functions (e.g., `/find-docs`, `/security-review`) if available.
3. Optimized CLI: Use high-performance tools (e.g., `rg`, `fd`, `jq`, `yq`, `hadolint`, `markdownlint-cli2`) for speed and accuracy.
4. Universal Fallback: Use standard commands (e.g., `grep`, `find`, `python`) as a last resort.

## 2. Core Toolset

- File Search: `rg` (ripgrep) is preferred over `grep`. `fd` is preferred over `find`.
- Data Processing: `jq` (JSON) and `yq` (YAML) for processing and formatting.
- Official Docs Search: `ctx7` or `/find-docs` for exploring library/API documentation.
- Lint: Use dedicated linters (e.g., `hadolint` for Docker, `markdownlint-cli2` for MD).

## 3. Usage Rules

- Environment Check: Verify tool availability with `command -v <tool>` before use.
- Project Context: Check for config files (e.g., `.editorconfig`, `Justfile`, `mise.toml`) to respect local settings.
- Safety: Prefer dry-run flags or read-only commands before making destructive changes.
