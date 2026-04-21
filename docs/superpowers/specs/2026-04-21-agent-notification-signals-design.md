# Agent Notification Signals Design

**Date:** 2026-04-21
**Scope:** Shared notification redesign for Claude Code, Codex CLI, and Gemini CLI

## Overview

Replace the current notification transport model with a shared signal model that
separates:

- meaning: what happened
- channel: how the user is notified

The immediate driver is WSL. `notify-send` is not reliable enough there, while
`play` is available in the current environment. The new design keeps WSL simple
by preferring sound-only signals, but it must also support Linux and macOS
setups where toast and sound may both be desirable.

This design applies only to the shared hook runtime under `~/.agents/hooks/`
and the thin agent adapters that call into it.

## Goals

- Keep agent-specific hook names out of the shared runtime API
- Support toast and sound as independent channels
- Prefer toast with sound on Linux and macOS
- Prefer sound-only on WSL
- Skip unsupported channels safely
- Show a missing-capability warning only once per shell session
- Leave room for future user-configurable notification policy without changing
  the adapter contract

## Non-Goals

- Building the user-facing settings feature in this change
- PowerShell or Windows-side fallback for WSL
- Guaranteeing identical notification behavior on every desktop environment
- Exhaustively supporting every Linux sound daemon or notification server

## Core Model

### Meaning Layer

The shared runtime handles only semantic signal events:

- `attention`
- `finished`
- `danger`

These names are stable across agents.

### Adapter Layer

Each agent keeps its own hook-specific naming and maps it into a semantic event:

| Agent | Hook/Event | Shared event |
| --- | --- | --- |
| Claude Code | `Notification` | `attention` |
| Claude Code | `Stop` | `finished` |
| Claude Code | `PreToolUse` deny on dangerous command | `danger` |
| Gemini CLI | `Notification` | `attention` |
| Gemini CLI | `Stop` | `finished` |
| Gemini CLI | `PreToolUse` deny on dangerous command | `danger` |
| Codex CLI | `Stop` | `finished` |
| Codex CLI | `PreToolUse` deny on dangerous command | `danger` |

If an agent does not expose an upstream hook for a semantic event, that event
remains unconnected in that adapter.

## File Layout

```text
home/dot_agents/hooks/
  lib/
    executable_notify.sh
  bin/
    executable_agent-signal.sh
    executable_agent-attention.sh
    executable_agent-finished.sh
    executable_agent-danger.sh
```

The shared executable names intentionally express semantic signals rather than
agent hook names.
The deployed filenames keep the `.sh` suffix so they stay consistent with the
rest of the hook tree and remain easy to invoke from adapters.

Planned API:

- library function: `emit_agent_signal EVENT AGENT [MESSAGE]`
- executable entrypoint: `agent-signal EVENT AGENT [MESSAGE]`
- thin wrappers:
  - `agent-attention`
  - `agent-finished`
  - `agent-danger`

Existing agent adapters continue to own hook payload parsing and any
agent-specific stdout/exit-code requirements.

## Channel Model

Two notification channels are modeled independently:

- `toast`
- `sound`

Policies may request:

- `toast`
- `sound`
- `toast+sound`

The runtime decides what can actually be satisfied on the current machine.

## Environment Capability Detection

Capability detection is based on actual command availability first, with
platform classification used only to choose the preferred order.

### WSL

Default preference:

- `sound`

Supported command candidates:

- sound: `play`
- toast: none

No Windows-side fallback is allowed.
WSL detection should not depend only on `WSL_DISTRO_NAME`; when the runtime is
inside a Linux container on top of WSL, `osrelease` or `version` may still
contain `microsoft` / `WSL` and should be treated as WSL.

### Linux

Default preference:

- `toast+sound`

Supported command candidates:

- toast with sound: `notify-send --hint=string:sound-name:...`
- toast without sound: `notify-send`
- sound without toast: `play`

The implementation should prefer a single toast command that already carries a
sound hint. If that cannot satisfy the effective sound channel, a separate sound
command may run afterward.

### macOS

Default preference:

- `toast+sound`

Supported command candidates:

- toast with sound: `osascript` using `display notification ... sound name ...`
- toast without sound: `osascript` using `display notification`
- sound without toast: `afplay`
- last-resort sound: `osascript -e "beep"`

`afplay` is reserved for cases where a sound must be played without a toast, or
where the chosen toast command cannot satisfy the requested sound channel.

## Event Policy

The initial default policy is event-based and environment-aware.

### WSL Sounds

`attention`:

```bash
play -n synth 0.22 sine 784 vol 0.12 fade q 0.01 0.22 0.06
```

`finished`:

```bash
play -n synth 0.18 sine 740 vol 0.12 fade q 0.01 0.18 0.05
sleep 0.3
play -n synth 0.18 sine 988 vol 0.10 fade q 0.01 0.18 0.05
```

`danger`:

```bash
play -n synth 0.28 triangle 660-990 vol 0.11 fade q 0.01 0.28 0.08
```

### Linux Defaults

Linux should prefer toast with sound first.

The concrete sound names should use pragmatic, common desktop defaults chosen
from mainstream examples rather than custom repo-specific assets. The exact
names are implementation details, but they should be event-specific and stable
enough to test.

If the desktop notification path cannot deliver sound reliably, the runtime may
supplement it with `play`.

### macOS Defaults

macOS should also prefer toast with sound first.

The concrete notification sound names should use built-in system defaults that
are widely available on stock macOS installations. When sound-only behavior is
needed, `afplay` should play a built-in system sound file instead of a custom
asset.

## Channel Resolution Rules

Given an effective policy and the detected environment capabilities, the runtime
resolves channels as follows:

1. Determine the requested policy for the event on this platform
2. Check whether the preferred combined implementation can satisfy it directly
3. If not, split the request into independent `toast` and `sound` work
4. Execute only the channels that are available
5. Emit at most one capability warning for each shell session

Examples:

- WSL `finished` requests `sound` and uses only the configured `play` sequence
- Linux `attention` requests `toast+sound` and prefers `notify-send` with sound
  hint
- macOS `danger` requests `toast+sound`; if the chosen `osascript` path cannot
  satisfy sound, it falls back to `afplay`

## Missing Capability Warning

When the requested channels cannot be fully satisfied, the runtime should warn
once per shell session and then stay quiet.

The warning must include:

- platform
- event
- effective policy
- requested channels
- available implementations
- checked commands

Example shape:

```text
[agent-signal] requested channels unavailable
platform=wsl event=finished policy=sound
toast available: none
sound available: none
sound checked: play
```

If a partial result is still possible, the warning should reflect that instead
of claiming total failure.

The warning marker should live in `TMPDIR` or `/tmp` and be scoped tightly
enough to avoid repeating on every hook invocation within the same shell
session.

## Adapter Responsibilities

Shared notification policy lives only in the shared runtime. Adapters should:

- parse the agent hook payload
- map hook context to a semantic event
- call the shared signal executable
- preserve the agent's required control flow

Adapters should not:

- detect platform capabilities
- select notification commands
- define event-specific sound patterns
- decide warning suppression behavior

## Future Configuration Extension

The implementation must be structured so users can later override notification
behavior without rewriting adapters.

This future feature is not implemented now, but the shared runtime should be
ready for a configuration source such as:

- event policy per platform
- preferred channels per event
- opt-in sound-only or toast-only modes
- custom sound names for Linux/macOS
- complete disable flags per event

To support that future cleanly, the runtime should keep:

- semantic event names stable
- channel resolution centralized
- environment capability detection centralized
- event defaults in a small, isolated data section instead of hard-coded across
  multiple adapters

## Testing Plan

### Shared Runtime

- capability detection chooses the correct candidate order on WSL, Linux, and
  macOS
- `toast`, `sound`, and `toast+sound` policies resolve correctly
- combined toast-with-sound paths suppress unnecessary extra sound playback
- missing capability warnings are emitted once and include available and checked
  commands

### Shared Wrappers

- `agent-attention` maps to `attention`
- `agent-finished` maps to `finished`
- `agent-danger` maps to `danger`

### Agent Adapters

- Claude adapters call the correct shared wrappers
- Gemini adapters call the correct shared wrappers
- Codex adapters call the correct shared wrappers
- `PreToolUse` only emits `danger` when the shared preflight policy denies the
  action

### Config Generation

- Claude settings merge remains idempotent
- Gemini settings merge remains idempotent
- Codex config and hooks template remain idempotent
- Existing unrelated settings remain preserved
