.PHONY: test lint lint-shell lint-markdown all

# Run all checks (default target)
all: lint test

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

test:
	bats tests/

# ---------------------------------------------------------------------------
# Linters
# ---------------------------------------------------------------------------

lint: lint-shell lint-markdown

lint-shell:
	find . -type f -name "*.sh" -print0 | xargs -0 shellcheck

lint-markdown:
	markdownlint-cli2 "**/*.md"
