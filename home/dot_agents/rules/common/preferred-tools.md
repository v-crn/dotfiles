# Preferred Tools

Use dedicated CLI tools when available. Priority order:

1. Project-specific wrapper (e.g., `make lint`) if present in the project
2. Direct CLI invocation
3. General-purpose fallback (e.g., Python) if CLI is unavailable

| Task | Preferred CLI |
| --- | --- |
| JSON formatting / processing | `jq` |
| Dockerfile linting | `hadolint` |
| Markdown linting / fixing | `markdownlint-cli2 --fix` |
| Library / API docs | `ctx7` |
