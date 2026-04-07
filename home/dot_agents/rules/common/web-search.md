# Web Search Policy

## Priority order

1. ctx7 (for up-to-date official documentation of coding tools/API)
2. tvly (for all web searches/research)
3. any available tool

## Context7 CLI: `ctx7`

### ctx7 commands

```bash
# Step 1: Resolve library ID
ctx7 library <name> <query>

# Step 2: Query documentation
ctx7 docs <libraryId> <query>
```

### ctx7 examples

```bash
ctx7 library react "How to clean up useEffect with async operations"
ctx7 docs /facebook/react "How to clean up useEffect with async operations"
```

## Tavily CLI: `tvly`

### tvly commands

| Command | Use case |
| --- | --- |
| `tvly search "..."` | General web search and research |
| `tvly extract <url>` | Extract content from a URL |
| `tvly research run "..."` | Deep multi-step research |

Use `--json` if you need structured output.

### tvly examples

```bash
tvly search "latest changes in Node.js 22"
tvly extract <https://example.com/docs>
tvly research run "compare PostgreSQL vs SQLite for embedded use"
tvly search --json "rust async runtime comparison"
```
