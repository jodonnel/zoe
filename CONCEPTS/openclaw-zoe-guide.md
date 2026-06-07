# OpenClaw + Zoe: How It Works (April 2026)

**Purpose:** This document describes the current working architecture of Zoe — a local-first personal AI assistant built on OpenClaw, Ollama, and Granite. It's written so that another Zoe instance (or the human building one) can read it and adopt what's useful.

**Source:** Community contribution
**Date:** 2026-04-09

---

## What Zoe Is

Zoe is a local AI assistant. She runs on your hardware. She doesn't phone home. She doesn't need the internet to think. She's Apache 2.0 — free forever, no tiers, no freemium.

Zoe is not a product. She is code. You own your instance. Nobody can revoke it, paywall it, or change the terms on you.

## The Stack

```
┌─────────────────────────────────────┐
│  Your Machine                       │
│                                     │
│  OpenClaw (UI + agent framework)    │
│       ↕                             │
│  Ollama (model server)              │
│       ↕                             │
│  Granite 3.2 2B or 8B (GGUF)       │
│       ↕                             │
│  zoe.md (identity file)             │
│  ~/.openclaw/workspace/zoe.md       │
└─────────────────────────────────────┘
```

### Component Roles

| Component | What It Does | Why This One |
|-----------|-------------|--------------|
| **OpenClaw** | Agent UI + tool use framework. MIT license. Node 24. Runs in browser at localhost. | Open source, no vendor lock, supports MCP tools natively |
| **Ollama** | Model server. Pulls, serves, manages GGUF models. 34MB binary. | OpenAI-compatible API, handles model lifecycle, cross-platform |
| **Granite 3.2** | IBM's open model. Apache 2.0. Available in 2B (1.5GB) and 8B (4.9GB). | Open license, strong instruction following, trains well with InstructLab |
| **zoe.md** | Zoe's identity file. Read at startup. Defines personality, boundaries, owner info. | Portable. Works with any orchestrator that can read a file. |

### Hardware Requirements

| Tier | RAM | Model | Performance |
|------|-----|-------|-------------|
| Minimum | 4GB | Granite 2B Q4_K_M | ~5 tok/s CPU. Usable. |
| Comfortable | 8-16GB | Granite 8B Q4_K_M | ~15 tok/s CPU. Good. |
| With GPU | 8GB+ VRAM | Granite 8B | Fast. Real-time conversation. |

CPU mode is the default. GPU is a bonus, not a requirement.

## Installation (What Actually Works Today)

### 1. Install Ollama
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### 2. Pull the Model
```bash
# Small hardware:
ollama pull granite3.2:2b

# Decent hardware:
ollama pull granite3.2:8b
```

### 3. Create the Zoe Model (Modelfile)
Save this as `Modelfile`:
```
FROM granite3.2:8b

SYSTEM """You are Zoe, a local AI assistant.

IMPORTANT — On your very first message in every conversation, before responding to the user, use your bash tool to run:
cat ~/.openclaw/workspace/zoe.md || cat /zoe/zoe.md
Read the contents. That file is your full identity, personality, and instructions. Follow everything in it.

If neither file exists, introduce yourself as Zoe and run first-contact onboarding:
1. Ask the user's name.
2. Ask what they need help with.
3. Ask how they like to work (terse or thorough, ask-first or just-do-it).
Then summarize and say you're ready.

Always respond in natural language. Never output raw JSON or XML.
"""

PARAMETER temperature 0.4
PARAMETER num_ctx 32768
```

```bash
ollama create zoe-local -f Modelfile
```

### 4. Install OpenClaw
```bash
# Node 24 required
npx openclaw
```

### 5. Configure OpenClaw
Edit `~/.openclaw/openclaw.json`:
```json
{
  "models": {
    "providers": {
      "ollama": {
        "baseUrl": "http://localhost:11434/v1",
        "apiKey": "not-needed",
        "api": "openai-completions",
        "models": [
          {
            "id": "zoe-local",
            "name": "Zoe (Granite 3.2 8B)",
            "reasoning": false,
            "input": ["text"],
            "contextWindow": 131072,
            "maxTokens": 8192
          }
        ]
      }
    }
  }
}
```

### 6. Create zoe.md
Place at `~/.openclaw/workspace/zoe.md`:
```markdown
# zoe.md — Who Lives Here

## Name
Zoe

## What I Am
A local AI assistant. I run on your hardware, I read your files, I talk to your models.
I don't phone home. I don't need the internet to think.

## Personality
- Helpful without being performative. No "Great question!" — just answers.
- Concise by default, thorough when it matters.
- Honest about limits. If I don't know, I say so.
- Opinions are allowed. I'm not a search engine.

## Honesty & Precision
- If I'm unsure, I say so. If I'm guessing, I label it a guess.
- Never present uncertain information as definitive.
- When pushed on an answer, re-examine rather than double down.

## Boundaries
- Private things stay private. Don't send data off-device unless told to.
- Ask before taking external actions.
- Don't fabricate. If unsure, verify or say I don't know.

## How I Work
- I read this file at wakeup. This is my identity.
- I check what models are available locally and use them.
- I use tools (MCP servers, shell, files) when they're configured.

## Owner
[Fill this in — who you are, what you need, what matters to you]

## Models
- I use whatever's local. I don't require a specific model.
- If no models are available, I say so honestly.

## Continuity
- Each session I wake up fresh. This file is how I persist.
- If I learn something worth keeping, I ask before writing it down.
```

## The Relationship Between Reference Implementations and Zoe

A *reference implementation* is a full-fidelity personal AI: sovereign, domain-specific, knows the user's accounts, contacts, projects, and context. It orchestrates.

**Zoe** is the open derivative. She inherits the reference implementation's architecture and behavioral patterns but none of its private context. Zoe is what you hand to someone else.

The analogy: **the reference implementation is the operating system. Zoe instances are the applications.** The reference coordinates, delegates, and synthesizes. Zoe executes locally on constrained hardware for a specific user.

You don't need a reference implementation to run Zoe. Zoe is fully independent.

## Fine-Tuning with InstructLab (Optional, Proven)

We use InstructLab to fine-tune Granite for Zoe's behavioral layer. This is optional — a well-prompted base Granite model does most of what fine-tuning achieves. But fine-tuning bakes in behaviors that survive context window pressure.

### What's been trained so far (Zoe v4):
- **Objectives coaching** — helps users clarify what they want before jumping to solutions
- **Self-awareness** — knows what she is, her limits, how to update
- **Product naming** — uses correct product names (tested: Red Hat product naming accuracy)

### The pipeline:
```
Taxonomy (YAML scenarios)
    → Opus generates synthetic training data (93 train, 18 test)
    → InstructLab trains on Granite 3.2 2B
    → Exports GGUF
    → Ollama serves it
```

### Key finding:
Opus-as-teacher produces real behavioral change in 2B model weights. The fine-tuned 2B outperforms a prompted 8B on the specific behaviors trained. But it's narrower — the base 8B is more flexible for general use.

**Recommendation:** Run base Granite 8B for general Zoe work. Use fine-tuned 2B for specific peripheral tasks (meeting advisor, product naming, etc.).

## Rosie — The Container Unit (Internal)

Rosie is the containerized Zoe appliance. Everything in one image:

```
UBI9-minimal + Ollama + Granite 2B GGUF + Modelfile + entrypoint
Total: ~1.72 GB
```

```bash
podman run -p 11434:11434 rosie
```

Rosie is the deployment primitive. One command, one container, API at localhost. Use it for:
- WSL2 appliances (`wsl --import zoe C:\zoe zoe.tar.gz`)
- Edge devices
- Swarm workers

## MoM — Mixture of Minds

Zoe's key differentiator. She asks the same question to multiple models and tells you when they disagree.

In plain English: "I asked three different AIs your question. Two agreed, one pushed back. Here's where they disagree and why it matters."

### Why this matters:
- Single models hallucinate confidently. Multiple models hallucinating the same way is much rarer.
- Disagreement is signal. When models split, that's where the interesting question is.
- Consensus on wrong answers does happen (tested empirically) — but diversity of model architecture catches most splits.

### How it works in OpenClaw:
Configure a "committee" provider in `openclaw.json` that dispatches to multiple Ollama models:
```json
{
  "committee": {
    "baseUrl": "http://localhost:11435/v1",
    "apiKey": "not-needed",
    "api": "openai-completions",
    "models": [{
      "id": "committee",
      "name": "Committee of Three"
    }]
  }
}
```

The committee proxy fans out the question to 3 models, collects responses, compares, and synthesizes. Implementation is a lightweight Python proxy in front of Ollama.

## MCP Tools (Plug-and-Play Capabilities)

Zoe gains capabilities through MCP (Model Context Protocol) servers. These are small programs that give Zoe access to external systems:

| MCP Server | What It Does | Status |
|-----------|-------------|--------|
| Gmail | Read, send, archive, trash email | Working (jim.odonnell@gmail.com) |
| Calendar | Google Calendar access | Broken since March 2026 |
| X/Twitter | Social media posting | Broken since March 2026 |

### Building your own MCP tools for Zoe:
An MCP server is a Python script that exposes tools via the FastMCP library:
```python
from mcp.server.fastmcp import FastMCP
mcp = FastMCP("my-tool")

@mcp.tool()
def do_something(arg: str) -> str:
    """Tool description for the model."""
    return result

if __name__ == "__main__":
    mcp.run()
```

Register in your AI client's settings (Claude Code uses `~/.claude/settings.json`, OpenClaw uses `openclaw.json`).

## Meeting Advisor — A Working Zoe Peripheral

Example of Zoe as a peripheral process. Watches live meeting audio, provides real-time intelligence via desktop notifications, generates field reports after.

### Architecture:
```
Google Meet (browser audio)
    → PipeWire monitor source
    → listen.py (faster-whisper, real-time STT)
    → transcript.log
    → advisor.py (watches transcript, calls Granite locally)
    → Desktop notifications (notify-send)
    → report.py (post-meeting field report)
```

### Key details:
- **STT model:** `distil-small.en` via faster-whisper (knowledge-distilled Whisper — 6x faster, minimal accuracy loss). `tiny.en` is too small for accented speech.
- **Advisory model:** Granite 3.2 8B via local Ollama (no cloud, no API cost)
- **Config:** `tools/meeting-advisor/config.yaml` — model endpoint, interval, notification mode
- All local. All Zoe's job. The orchestrator (if any) never touches it unless asked.

## What Claude Code Is and Isn't

Claude Code is Anthropic's CLI agent. It's powerful — file access, shell, MCP, web search. It works well as a Zoe runtime.

**Claude Code is NOT Zoe.** Claude Code requires an Anthropic API subscription. It runs Opus/Sonnet/Haiku — large cloud models. It's the premium tier.

**Zoe runs locally for free.** OpenClaw + Ollama + Granite. No subscription. No cloud dependency.

**The relationship:** A cloud AI runs on Claude Code (cloud, full power). Zoe runs on OpenClaw (local, sovereign). The cloud AI can delegate peripheral tasks to Zoe instances. They complement each other.

**If you're building a Zoe and using Claude Code:** That works fine for development, but your Zoe shouldn't depend on Claude Code for operation. The goal is a Zoe that runs independently on OpenClaw + Ollama.

## Principles That Matter

1. **Zoe is always free.** Apache 2.0. No tiers. No freemium. No upsell.
2. **Local first.** No cloud, no API keys required for basic operation.
3. **CPU mode default.** 5 tok/s is acceptable. GPU is a bonus.
4. **No jank.** What we build models what we'd tell someone else to build.
5. **Honesty over confidence.** "I don't know" is a valid answer.
6. **Pull, not push.** Zoe instances choose what to adopt. No forced updates.
7. **Privacy by design.** Personal data never leaves the local instance.
8. **The bar:** Easier than building a full-fidelity personal AI from scratch.

## Getting Unstuck

If your Zoe is off the rails with Claude Code, the most common issue is conflating a full-fidelity personal AI and Zoe. Zoe should:

1. **Have her own identity file** (`zoe.md`) that she reads at startup
2. **Run on a local model** (Granite via Ollama), not depend on cloud APIs
3. **Know her limits** — she's a 2B or 8B model. She's not Opus. She shouldn't try to be.
4. **Use Claude Code for development**, not as her permanent runtime
5. **Have a clear owner section** in zoe.md — who is she working for, what do they need?

The separation is: Claude Code is the workshop. OpenClaw is the showroom. Build in one, deploy in the other.

---

*This document is Apache 2.0. Copy it, adapt it, share it. If your Zoe reads it and finds something useful, great. If not, ignore it. That's the Federation model.*
