.PHONY: test lint lint-shell lint-markdown all diff apply

CHEZMOI_SOURCE_DIR=.

# Run all checks (default target)
all: lint test

# ---------------------------------------------------------------------------
# Chezmoi
# ---------------------------------------------------------------------------

diff:
	chezmoi diff --source $(CHEZMOI_SOURCE_DIR)

apply:
	chezmoi apply --source $(CHEZMOI_SOURCE_DIR)

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
