# Codex Config Merge Design

Date: 2026-04-22

## Overview

Refine `home/dot_codex/run_apply-codex-config.sh` so the generated
`~/.codex/config.toml` is richer as a reference, while staying practical for
daily use.

The current script already merges a managed config block into an existing
`config.toml` and preserves unknown sections. This design keeps that merge
strategy and narrows the change to the managed settings template and the list of
managed top-level keys.

The managed template should continue to be readable as a real config file, not
as a dump of every possible sample option.

## Design Goals

- Keep the existing merge behavior and backup flow unchanged
- Stop managing `model` so new model releases do not require dotfiles updates
- Keep a broader set of realistic future options as commented examples
- Add the official Codex sample config URL as an inline reference comment
- Preserve user-managed values and unknown future sections whenever possible

## Non-Goals

- Reworking the merge algorithm
- Adding validation for every Codex config field
- Converting this script into a general-purpose TOML editor
- Mirroring the official sample config verbatim

## Current Constraints

- `home/dot_codex/run_apply-codex-config.sh` is currently modified and
  uncommitted; those edits are treated as the baseline for the implementation
- The file is a `run_` script used by chezmoi, not a deployed dotfile
- Existing `~/.codex/config.toml` may already contain user-managed keys such as
  `model` and custom sections that should survive future applies

## Recommended Approach

Use a practical middle ground between a minimal config and a full sample dump.

- Keep active managed defaults for values this repo wants to control:
  `approval_policy`, `sandbox_mode`, `[features]`, and managed profiles
- Keep commented examples for realistic future tuning points:
  `service_tier`, `model_reasoning_effort`, notification-related options,
  selected `[tui]` options, and `background_terminal_max_timeout`
- Remove `model` from the managed template and from the managed-key stripping
  list
- Remove low-value or high-confusion options from the template unless there is a
  strong reason to keep them, especially fields that override model internals or
  require frequent maintenance

## Configuration Policy

### Active Managed Values

These remain explicitly written by the script:

- `approval_policy = "on-request"`
- `sandbox_mode = "workspace-write"`
- `[features]` values currently enabled by dotfiles
- Managed profiles such as conservative and development
- The existing `[tui]` `status_line` block, unless implementation review finds a
  reason to trim it

### Commented Future Options

These stay close to the active settings as commented examples because they are
plausible knobs for future personal tuning:

- `service_tier`
- `model_reasoning_effort`
- notification toggles and conditions
- selected TUI presentation options that fit the existing status-line-oriented
  setup
- `background_terminal_max_timeout`
- `personality` if it still matches the current Codex config schema when the
  change is implemented

Each commented option should have a short explanation focused on when it is
useful, not a long copy of upstream documentation.

### Options To Exclude

The template should not keep options that add maintenance burden or invite
misconfiguration in normal use:

- `model`
- `model_context_window`
- `model_auto_compact_token_limit`
- `tool_output_token_limit`
- `model_catalog_json`

If implementation review shows that one of these is now important for normal
operation, it can be reintroduced only with a strong justification.

## Merge Behavior

The merge flow stays the same:

1. Back up the current `~/.codex/config.toml`
2. Remove managed top-level keys and managed sections from the existing file
3. Preserve unknown sections and user-managed settings
4. Append the normalized managed block

The only managed-key change in scope is removing `model` from the top-level key
removal regex. This ensures the script no longer deletes a user-defined model
from an existing config file.

Managed sections remain unchanged unless implementation review finds that a new
commented example requires a different section to be owned by the script.

## Reference Comment

The managed template should include a short comment pointing to the official
reference sample:

- `https://developers.openai.com/codex/config-sample`

The comment should make clear that the local template is curated from that
reference and intentionally does not include every upstream option.

## Error Handling

No behavioral changes are planned for error handling.

- Missing `awk` still causes a warning and a no-op exit
- Failed merge steps still abort without overwriting the target file
- Existing backup behavior remains intact

## Testing

Implementation should verify at least these cases:

1. New install: no existing `~/.codex/config.toml` produces the curated config
   with the reference URL comment and commented future options
2. Existing config with `model = "..."`: rerunning the script preserves that
   `model` entry while refreshing managed values
3. Existing config with unknown sections: rerunning the script preserves those
   sections unchanged
4. Idempotency: rerunning the script without other changes does not create
   duplicate managed blocks or blank-line drift

Manual shell-based verification is sufficient for this change unless the repo
already has a test harness for this script.

## Risks And Mitigations

- Risk: keeping too many commented options turns the file into noisy reference
  material
  Mitigation: keep only realistic future knobs and remove low-signal internals
- Risk: removing `model` from managed keys changes behavior for users who relied
  on dotfiles to clear it
  Mitigation: document the new policy clearly in comments and the implementation
  summary
- Risk: upstream config schema may evolve
  Mitigation: keep the official sample URL in comments and curate only a small
  set of optional fields
