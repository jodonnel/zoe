# Memory Architecture — Reference Implementation

Zoe persistent memory is a three-layer system. Each layer is faster to query and narrower in scope than the one below it. The system fires before the LLM generates a response — context arrives pre-loaded, not retrieved mid-conversation.

---

## Overview

```
Incoming prompt
     |
     v
[Layer 1] Hook preprocessor — fires first, before the LLM sees the prompt
     |
     v
[Layer 2] Domain + task retrieval — keyword match on structured memory files
     |
     v
[Layer 3] Semantic fallback — vector similarity on embedded memory chunks
     |
     v
LLM generates response with pre-loaded context
```

The hook preprocessor is the entry point. It intercepts every prompt, queries layers 2 and 3, and injects relevant context into the system prompt before the model is invoked.

---

## Layer 1 — Hook Preprocessor

A script (Bash or Python) registered as a pre-LLM hook in the AI harness. Receives the incoming prompt, queries memory, and outputs an augmented system prompt.

Key properties:
- Synchronous — runs before every LLM call
- Fast — must complete in under 500ms or it blocks the user
- Deterministic — same query always returns the same context set
- No LLM involved — pure text/vector retrieval

Hook registration pattern (Hermes):
```yaml
hooks:
  - event: pre_llm_call
    command: bash /path/to/memory-hook.sh
    timeout: 3
```

Hook registration pattern (Claude Code):
```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": "/path/to/memory-hook.sh"}]
      }
    ]
  }
}
```

---

## Layer 2 — Structured Memory (DuckDB + FTS5)

Domain and task memory stored as structured records in DuckDB with full-text search (FTS5). Queried by keyword match against the incoming prompt.

Schema pattern:
```sql
CREATE TABLE memory (
    id          INTEGER PRIMARY KEY,
    domain      TEXT,
    topic       TEXT,
    content     TEXT,
    importance  TEXT,
    created_at  TIMESTAMP,
    updated_at  TIMESTAMP
);

CREATE VIRTUAL TABLE memory_fts USING fts5(
    id UNINDEXED,
    domain,
    topic,
    content,
    tokenize='porter unicode61'
);
```

Query pattern:
```python
def query_structured(prompt: str, limit: int = 5) -> list[str]:
    results = db.execute("""
        SELECT content, importance, domain
        FROM memory_fts
        WHERE memory_fts MATCH ?
        ORDER BY rank
        LIMIT ?
    """, [prompt, limit]).fetchall()
    return [r[0] for r in results]
```

Why DuckDB: Single-file database, no server process, FTS5 handles typos and stemming, runs in-process.

---

## Layer 3 — Semantic Memory (Lance + Nomic Embed)

Vector similarity search for concepts that do not match on keywords. Uses Lance (columnar vector store) with Nomic Embed (768-dim embeddings) or any compatible embedding model.

Why this layer exists: Keyword search misses synonyms and related concepts. Semantic search catches the gap.

Setup pattern:
```python
import lancedb

db = lancedb.connect("/path/to/lance-db")
table = db.open_table("memory")
embedding = embed_text(prompt)
results = table.search(embedding).limit(3).to_pandas()
```

Embedding model: Nomic Embed Text v1.5 (768-dim, Apache 2.0, runs locally via Ollama)
```bash
ollama pull nomic-embed-text
```

Why Lance: Columnar, persistent on disk, Python-native (pyarrow), works offline.

---

## Context Injection Pattern

The hook assembles retrieved memories into a block prepended to the system prompt:

```python
def build_context_block(prompt: str) -> str:
    structured = query_structured(prompt, limit=5)
    semantic = query_semantic(prompt, limit=3)

    if not structured and not semantic:
        return ""

    block = "## Retrieved Context\n\n"
    for m in structured:
        block += f"- {m}\n"
    if semantic:
        block += "\n### Related context:\n"
        for m in semantic:
            block += f"- {m}\n"
    return block
```

---

## Memory Decay and Importance

| Importance | Suggested TTL |
|---|---|
| critical   | Permanent    |
| high       | 90 days      |
| medium     | 30 days      |
| low        | 7 days       |

```sql
DELETE FROM memory
WHERE importance = 'low' AND updated_at < NOW() - INTERVAL 7 DAYS;
```

---

## What to Store vs. What Not to Store

Store: User preferences that change behavior, recurring corrections, environment facts, domain conventions.

Do not store: Task progress, PR/issue/commit numbers, completed-work logs, anything stale within a week.

---

## Minimal Implementation (DuckDB FTS5 only)

If embedding infrastructure is not available, DuckDB FTS5 alone covers 80% of use cases:

```bash
pip install duckdb

python3 -c "
import duckdb
db = duckdb.connect('/path/to/memory.db')
db.execute('''CREATE TABLE IF NOT EXISTS memory (
    id INTEGER PRIMARY KEY,
    topic TEXT,
    content TEXT,
    importance TEXT DEFAULT \'medium\'
);''')
"
```

---

## Integration with Hermes Bridges

The memory system is harness-agnostic. Any Hermes session using cc-bridge or grok-bridge benefits from the same hook. The bridge does not need to know memory exists — the hook runs before Hermes sends the request to the bridge.

See hermes-bridges.md for bridge setup.

---

*Apache 2.0. No subscriptions. No cloud required. Runs entirely on your machine.*
