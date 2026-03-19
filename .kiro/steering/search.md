# Code Search Guidelines

## Use grepai MCP, not grep

Always use the `grepai` MCP tools for code search and navigation. Never use grep, ripgrep, or text-based search for exploring the codebase.

### Available MCP Tools

- `grepai_search` — semantic natural language search (e.g. "audio fade logic", "timer expiry handling")
- `grepai_trace_callers` — find all callers of a function before modifying it
- `grepai_trace_callees` — find what a function depends on
- `grepai_trace_graph` — full call graph around a symbol
- `grepai_index_status` — check index health

### Examples

Instead of:
```bash
grep -r "playSounds" WhiteNoise/
```

Use:
```
grepai_search: "play sounds audio"
grepai_trace_callers: "playSounds"
```

Instead of:
```bash
grep -r "TimerService" WhiteNoise/
```

Use:
```
grepai_search: "timer service lifecycle"
grepai_trace_graph: "TimerService"
```

### Why

grepai uses vector embeddings via Ollama (`nomic-embed-text`) to understand code meaning — it finds conceptually related code even when naming differs. The index lives in `.grepai/` and is kept fresh by the `grepai watch` daemon.
