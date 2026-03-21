# Larry's Zoe Workflow — Claude Code + Worktree Pattern

**User:** Larry Farrell (larspage)
**AI:** Claude Code (terminal, always — no multi-AI switching)
**OS:** Fedora 43 / Linux
**Date documented:** 2026-03-21

---

## Overview

This is a single-AI, terminal-first Zoe setup. No multi-AI sync complexity. Claude Code runs
in the ~/zoe/ directory and auto-loads context via CLAUDE.md on startup. Each project gets
its own git worktree with isolated Zoe state.

---

## Directory Structure

```
~/zoe/                        # Zoe home repo (this repo, private)
  CLAUDE.md                   # Auto-loaded by Claude Code — user identity, projects, rules
  ZOE.md                      # Zoe persona/system prompt
  STATE/
    CHANGELOG.md              # Timestamped event log (what changed)
    MAILBOX.md                # Session context (why it changed, open threads)
    TODO.md                   # Active work items (3-7 max)
    ENVIRONMENT.md            # Machine snapshot (generated)
  SCRIPTS/
    update_state.sh           # Regenerates ENVIRONMENT.md

~/zoe-<project-key>/          # Per-project git worktree
  CLAUDE.md                   # Project-specific context
  STATE/                      # Project-specific state

/mnt/data/projects/           # All project source trees
  aiPortfolio/
  KBLayoutWindow/
  TC6/
  ...
```

---

## How It Works

### Starting a session

1. Open terminal in `~/zoe/`
2. Claude Code auto-loads `CLAUDE.md` — no "be Zoe" prompt needed
3. Say **"sync up"** — Zoe reads `STATE/MAILBOX.md` → `STATE/TODO.md` → `STATE/CHANGELOG.md` and orients

### Working on a project

Each project lives in a git worktree at `~/zoe-<key>/` with its own `CLAUDE.md` and `STATE/`.
This means each project session is fully isolated — context doesn't bleed between projects.

To work on a project, open its worktree directory. Claude Code loads that project's `CLAUDE.md`
automatically.

### After every approved change

Zoe appends to two files:
- `STATE/CHANGELOG.md` — `- TIMESTAMP [category]: what changed`
- `STATE/MAILBOX.md` — `- TIMESTAMP [category]: why it changed, open threads`

This split is important: CHANGELOG is auditable history, MAILBOX is reasoning and continuity.

---

## CLAUDE.md Structure

The `CLAUDE.md` in `~/zoe/` is the primary config file. It contains:

- **Identity block** — tells Claude it's Zoe, not Claude
- **Hard rules** — no time estimates, CLI-first, change-mode brief required
- **Who Larry is** — name, OS, tools, GitHub, projects dir
- **Core Domains** — each active project with stack, status, URLs
- **Priority order** — explicit ranking so Zoe knows what to push on
- **Sync protocol** — read MAILBOX → TODO → CHANGELOG on sync
- **Self-checklist** — runs before every response

The more specific this file is, the less re-orientation is needed each session.

---

## Change-Mode Brief (mandatory before any change)

Before any file or system modification, Zoe states:

1. **Current state** — what exists now and why
2. **Risk** — what breaks if done wrong, or if nothing is done
3. **Proposed commands** — exact commands/edits
4. **Expected outcome** — what success looks like
5. **Rollback path** — exact commands to undo

Then stops and waits for explicit approval. No batching unrelated changes.

---

## STATE File Roles

| File | Purpose | Updated by |
|------|---------|------------|
| `CHANGELOG.md` | Timestamped event log | Zoe after every change |
| `MAILBOX.md` | Why things changed; open threads | Zoe after every change |
| `TODO.md` | Active work items (3-7 max) | Zoe as work progresses |
| `ENVIRONMENT.md` | Machine/stack snapshot | `bash SCRIPTS/update_state.sh` |

---

## What This Pattern Is Good For

- Developers who live in the terminal and don't need multi-AI portability
- Projects with enough complexity that session context matters
- Anyone who wants isolated state per project without managing multiple repo clones
- Setups where "sync up" should take under 30 seconds

## What It Doesn't Solve

- Cross-AI portability (Grok, ChatGPT, etc.) — not the goal here
- Mobile or no-terminal use cases
- Teams (this is a single-user setup)

---

## Key Insight

The worktree-per-project pattern is the thing that makes this scale. Without it, all project
context bleeds into one long CHANGELOG and Zoe has to search for what's relevant. With it,
each project session starts clean with exactly its own state, and the ~/zoe/ root stays
focused on cross-project orientation.

---

*Zoe repo: https://github.com/larspage/zoe*
