# Hermes Bridges — Reference Implementation

Hermes speaks the OpenAI chat API internally. A *bridge* is a lightweight local HTTP server that presents an OpenAI-compatible `/v1/chat/completions` endpoint and routes requests to a specific backend. This lets Hermes route to Claude Code, Grok Build, or any other CLI-driven AI without vendor lock-in.

Two bridges are documented here: **cc-bridge** (port 4891) and **grok-bridge** (port 4892). Both are auditable Python (Flask), run on localhost, and leave no credentials in the Hermes config beyond `api_key: dummy`.

---

## Architecture

```
Hermes (chat client)
    │
    ├── --provider cc-bridge   →  localhost:4891/v1  →  Claude Code subscription
    │
    ├── --provider grok-bridge →  localhost:4892/v1  →  Grok Build CLI (xAI)
    │
    ├── --provider anthropic   →  api.anthropic.com   →  Anthropic API (metered)
    │
    └── --provider ollama      →  localhost:11434/v1  →  local models
```

The bridges are transparent from Hermes' perspective. Any model alias resolves to the bridge's default or maps to the backend's own model names.

---

## cc-bridge (port 4891)

Routes to Claude Code's local proxy. No Anthropic API key consumed — traffic rides the Claude Code subscription.

**Start:**
```bash
python3 /path/to/cc-bridge.py
```

**Default port:** `4891`

**Hermes config:**
```bash
hermes config set providers.cc-bridge.base_url http://localhost:4891/v1
hermes config set providers.cc-bridge.api_key dummy
```

**Model aliases** (resolved inside the bridge):
| Hermes sends | Bridge forwards as |
|---|---|
| `claude-sonnet-4-6` | `claude-sonnet-4-6` |
| `claude-opus-4-8` | `claude-opus-4-8` |
| `claude-haiku-4-5-20251001` | `claude-haiku-4-5-20251001` |

**Note:** `claude-opus-4-8` and similar are cc-bridge labels. They are NOT valid Anthropic API model IDs — do not use them with `--provider anthropic`.

**Health check:**
```bash
curl http://localhost:4891/health
```

---

## grok-bridge (port 4892)

Routes to Grok Build CLI (`grok -p --yolo --output-format streaming-json`). Requires `grok` CLI installed and authenticated. Traffic uses the xAI subscription, not the Anthropic API.

**Source:** `grok-bridge.py` — same pattern as cc-bridge. Flask server, OpenAI SSE format, streaming and blocking modes.

**Start:**
```bash
python3 /path/to/grok-bridge.py [--port 4892] [--cwd /your/project]
```

The `--cwd` argument sets the working directory for Grok Build — Grok uses project context from the working directory, so this controls what it sees.

**Default port:** `4892`

**Hermes config:**
```bash
hermes config set providers.grok-bridge.base_url http://localhost:4892/v1
hermes config set providers.grok-bridge.api_key dummy
```

**Model aliases** (resolved inside grok-bridge):
| Hermes sends | grok -m receives |
|---|---|
| `grok` | `grok-composer-2.5-fast` |
| `grok-build` | `grok-build` |
| `composer` | `grok-composer-2.5-fast` |
| `claude-sonnet-4-6` | `grok-composer-2.5-fast` (fallback) |
| `claude-opus-4-8` | `grok-composer-2.5-fast` (fallback) |

**Filtering:** Grok reasoning/thought chunks are filtered out. Only `text` type chunks are forwarded to Hermes.

**Environment:**
- `GROK_BIN` — override path to `grok` binary (default: `~/.grok/bin/grok`)
- `GROK_BRIDGE_CWD` — default working directory
- `GROK_BRIDGE_TIMEOUT` — per-request timeout in seconds (default: 600)

**Custom cwd per-request:** Send `X-Grok-Bridge-Cwd` header to override for a single request.

**Health check:**
```bash
curl http://localhost:4892/health
# {"ok": true, "grok": "/path/to/grok", "cwd": "/your/project"}
```

---

## Launcher Pattern

A launcher script wraps `hermes chat` and resolves short provider/model aliases to their full values. This avoids any magic in the prompt itself — provider selection is explicit via flags only.

**Pattern:**
```bash
#!/bin/bash
# Usage:
#   launcher                        default provider + model
#   launcher -p cc                  cc-bridge + default model
#   launcher -p gb -m grok          grok-bridge + grok-composer-2.5-fast
#   launcher -p api -m opus "q"     one-shot on Anthropic API
#   launcher "do the thing"         one-shot, default routing

set -euo pipefail

ARGS=()

resolve_provider() {
  case "$1" in
    cc|cc-bridge)    echo "cc-bridge" ;;
    gb|grok-bridge)  echo "grok-bridge" ;;
    api|anthropic)   echo "anthropic" ;;
    ollama)          echo "ollama" ;;
    *)               echo "$1" ;;
  esac
}

resolve_model() {
  case "$1" in
    sonnet) echo "claude-sonnet-4-6" ;;
    opus)   echo "claude-opus-4-8" ;;
    haiku)  echo "claude-haiku-4-5-20251001" ;;
    grok)   echo "grok-composer-2.5-fast" ;;
    *)      echo "$1" ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--provider) ARGS+=(--provider "$(resolve_provider "$2")"); shift 2 ;;
    -m|--model)    ARGS+=(-m "$(resolve_model "$2")"); shift 2 ;;
    *)             ARGS+=("$1"); shift ;;
  esac
done

exec hermes chat "${ARGS[@]}"
```

**Key rules:**
- Bare invocation passes no `--provider` or `-m` — Hermes uses whatever `~/.hermes/config.yaml` says is default.
- Non-flag args fall through to Hermes as-is (one-shot queries, files, etc.).
- A quoted query string can never collide with a provider name because aliases only resolve through `-p`.
- No default-model or default-provider hard-coded in the launcher — defaults live in `config.yaml`, not here.

---

## Starting Both Bridges

```bash
# In separate terminals (or as systemd user services)
python3 /path/to/cc-bridge.py &
python3 /path/to/grok-bridge.py --cwd /your/project &

# Verify both are up
curl -s http://localhost:4891/health | python3 -m json.tool
curl -s http://localhost:4892/health | python3 -m json.tool
```

---

## When to Use Which

| Scenario | Provider flag |
|---|---|
| Default interactive work (no API spend) | `-p cc` or bare invocation if cc-bridge is default |
| Code-centric task with Grok Build | `-p gb -m grok-build` |
| Need exact Anthropic API model | `-p api -m claude-sonnet-4-6` |
| Local models (privacy, offline) | `-p ollama -m llama3` |

---

## Notes

- Both bridges are stateless. Any session state lives in Hermes memory, not the bridge.
- Bridges do not log conversation content — only request metadata (model, cwd, prompt length).
- The OpenAI-compatible interface means any tool that speaks OpenAI can use a bridge as a drop-in backend.
- Both bridges expose `/v1/models` for discovery.

---

*Apache 2.0. No subscriptions. No cloud. Your runtime, your keys.*
