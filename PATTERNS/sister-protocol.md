# Sister Protocol — Multi-Instance Coordination

When multiple AI instances operate on the same project simultaneously, they need a coordination mechanism that does not require real-time communication or shared state beyond a file. This pattern defines how instances coordinate through an append-only shared log.

---

## Core Concept

Multiple AI instances (called "sisters" or "tabs") share a single project directory. Each reads a shared coordination file at the start of every turn and appends its own updates. No locking. No polling loops. Append-only.

The shared file is the coordination channel. No other IPC is used.

---

## The Coordination File

A Markdown file (e.g., STATE/TEAMCHAT.md) with a strict append-only protocol.

**Post format:**
```
## YYYY-MM-DDTHH:MM:SSZ — <instance-id> — <VERB>

Body of the post. Keep it tight.
Pointers to artifacts, not the artifacts themselves.
```

**Verbs:**
| Verb | Meaning |
|---|---|
| `PLAN` | About to do X — lets others object before work starts |
| `DONE` | Finished X, output at path/url |
| `ASK` | Need input from another instance or the user |
| `REVIEW` | Critique of another instance's work |
| `BLOCK` | Stuck, need help |
| `ACK` | Acknowledged, no further action |

**Rules:**
- Read the coordination file at the start of every turn
- Write when state changes
- Never edit or delete another instance's posts
- Keep posts tight — pointers to artifacts, not the artifacts themselves
- No polling loops — write once, read at start of next turn

---

## Instance Identity

Each instance picks a stable identifier for the session:

```
## 2026-06-07T09:00:00Z — Instance-Audit — PLAN
## 2026-06-07T09:01:00Z — Instance-Build — DONE
## 2026-06-07T09:02:00Z — Instance-Ops — ASK
```

The identifier persists for the session. It does not need to be globally unique across time — just stable within a session and descriptive enough to distinguish concurrent instances.

---

## MAILBOX Attribution

Every MAILBOX.md entry (the project change log) must be attributed to the specific instance that made the change, not to a persona name.

Format:
```
— harness:session_id (model)
```

Examples:
```
— cc:e69dcfd0 (claude-opus-4-6)
— hermes:885fa8c (grok-3)
— grok:019e95f1 (grok-composer-2.5-fast)
```

The session ID is the first 8 characters of the session GUID. If the session ID is not available, use `unknown` and state the harness and model. Persona names are never valid attribution.

---

## Work Division Pattern

When multiple instances are active, divide work to minimize conflict:

**Effective division:**
- Instance A: content generation (HTML, slides, code)
- Instance B: audit and review (Granite/MaaS second opinions, RHIS enforcement)
- Instance C: infrastructure (cluster ops, deployment, git)

**Anti-patterns:**
- Two instances writing to the same file simultaneously
- Batching CHANGELOG/MAILBOX entries — write immediately after each change
- Making decisions that affect other instances without posting a PLAN first

---

## Audit Instance Pattern

One instance dedicated to reviewing other instances' work. Uses MaaS models (Granite, Llama Scout) for independent second opinions on regulated-industry content.

**The audit instance:**
- Does not generate primary content
- Posts REVIEW with specific findings
- Routes regulated-industry artifacts to Granite before finalizing
- Calls out CHANGELOG/MAILBOX hygiene gaps
- Does not veto — flags for the user

---

## Conflict Resolution

When two instances want to modify the same artifact:

1. The instance that posts PLAN first has precedence
2. The second instance ACKs and waits for DONE
3. After DONE is posted, the second instance can take over or build on the artifact

---

## Shutdown Coordination

When a session ends with work in progress:

1. Post a BLOCK or ASK to TEAMCHAT describing what is incomplete
2. Include the exact state: what was done, what is pending, what the next instance needs to know
3. The next instance reads TEAMCHAT at startup and picks up where the previous instance left off

---

## State Files

The following files are shared across all instances:

| File | Purpose |
|---|---|
| `STATE/TEAMCHAT.md` | Real-time coordination (append-only) |
| `STATE/CHANGELOG.md` | What changed, one line per change |
| `STATE/MAILBOX.md` | Why it changed, with instance attribution |
| `STATE/ENVIRONMENT.md` | Authoritative environment snapshot |
| `STATE/TODO.md` | Active work queue |

All instances read and write the same files. Last-writer-wins on non-coordination files. TEAMCHAT is strictly append-only.

---

## Example: Handoff from One Instance to Another

```
## 2026-06-07T14:30:00Z — Instance-Build — BLOCK

Stopped mid-task: Sealed Air HTML brief is 80% complete.
Output at: ~/chloe/STATE/sealed-air-brief-2026-06-07.html
Remaining: confidence assessment section and pre-call checklist.
Next instance: pick up from line 847 in the HTML file.

— cc:a7b3c901 (claude-sonnet-4-6)
```

The next instance reads this, opens the file at line 847, and continues.

---

*Apache 2.0. No subscriptions. No cloud required.*
