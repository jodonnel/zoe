# Sync Protocol Design Proposals

**Author:** Architect
**Date:** 2026-02-22
**Input:** Scout's gap analysis (DEBATE/problem.md)
**Question:** How should Zoe solve bootstrap, schema portability, and write-back across AI boundaries?

---

## Design 1: Paste-First Protocol (The Disciplined Habit)

**One-line summary:** Teach the user one ritual — run `new_session.sh` at session end, paste the output at session start — and make ZOE.md enforce that ritual explicitly.

### Core Assumption

The user is at a terminal at least once per day (when they first use Claude Code), and can be trained to run a single script before switching AIs. The problem is not the mechanism — `new_session.sh` already exists and works — the problem is that the spec never mentions it where users look for it.

### Sub-problem 1 — Bootstrap without file access

Add a mandatory prompt to the "Sync Up" section of ZOE.md:

> "If I cannot read your repo directly, I need you to run one command on your machine and paste the output here:
> `bash SCRIPTS/new_session.sh`
> If you don't have a terminal open, paste your last sync block instead. If you have neither, tell me and I'll run First Contact."

This turns bootstrap from a broken implicit assumption into an explicit three-step fallback ladder: (1) AI reads files directly, (2) user pastes `new_session.sh` output, (3) First Contact. Each rung is reachable and named.

The script already exists. ZOE.md just needs to say it exists and when to use it.

### Sub-problem 2 — State schema portability

Add a short "Sync Block Format" section to ZOE.md that defines the canonical markers any Zoe instance must recognize:

```
<!-- zoe-sync-v1 -->
## Zoe Sync-Up — [TIMESTAMP]
**User:** [name]
### Last 5 Changelog Entries
[entries]
### Current TODO
[active/backlog sections]
### Open Mailbox Items
[active threads]
### Environment (summary)
[key env lines]
```

Instruct every Zoe instance: "When you receive a block starting with `<!-- zoe-sync-v1 -->` or the header `## Zoe Sync-Up`, parse each section by its `###` heading. Treat it as authoritative state. Do not summarize or compress it — orient against it."

The version marker (`v1`) makes future format changes detectable. The section headers are already produced by `new_session.sh`; this design just makes the parser instructions explicit in ZOE.md.

### Sub-problem 3 — Write-back without terminal access

Accept that non-Claude AIs are effectively read-only, but make that explicit and give the user a write-back artifact to act on manually. At session end, any Zoe instance (including Grok) that made meaningful decisions outputs:

```
## Session Output — [TIMESTAMP]
Paste this into your terminal to record what we did:

cat >> STATE/CHANGELOG.md << 'EOF'
- [TIMESTAMP] [category]: [what happened]
EOF

cat >> STATE/MAILBOX.md << 'EOF'
- [TIMESTAMP] [context]: [why it happened, open threads]
EOF
```

This is a single copy-paste action for the user — one block, already formatted, already CLI-ready. The user runs it in their terminal. It takes 10 seconds. ZOE.md adds to its self-checklist: "If I cannot write files, did I output a write-back block?"

### Fatal Flaw

This design requires the user to run `new_session.sh` before they switch AIs — not after they're already in Grok. If they forget (they will forget), they arrive at Grok with nothing to paste, and the spec's three-rung ladder collapses immediately to First Contact. The habit is the entire load-bearing structure, and habits are fragile. The design works perfectly for the minority of users who are already disciplined. It does nothing for the majority who aren't.

---

## Design 2: State-as-URL (The Hosted Snapshot)

**One-line summary:** After every Claude Code session, push a machine-readable state snapshot to a known GitHub URL; any AI can fetch it via curl or the user pastes the URL, eliminating the need to remember what to paste.

### Core Assumption

The user has a GitHub repo (Level 3), and their AI either has internet access (Grok, ChatGPT with browsing) or they can paste a short URL. The friction point is not "paste a blob" but "know what blob to paste." A URL is easier to remember than a file path, and it can be fetched without the user manually opening files.

### Sub-problem 1 — Bootstrap without file access

Add a script `SCRIPTS/push_state.sh` that runs at session end (or on a git hook after any commit) and publishes a current `STATE/sync.json` to the repo. The file is always at a predictable URL:

```
https://raw.githubusercontent.com/[USER]/zoe/main/STATE/sync.json
```

The "Sync Up" section of ZOE.md becomes:

> "If I can fetch URLs, I'll retrieve your state automatically — just tell me your GitHub username. If I can't, paste this URL into your browser, copy the result, and paste it here. If you don't have a repo, run First Contact."

The bootstrap ladder is now: (1) AI fetches URL directly, (2) user pastes URL into browser and copies result, (3) First Contact. Step 2 is browser-friendly and works on mobile. The user only needs to remember one thing: their GitHub username.

### Sub-problem 2 — State schema portability

`STATE/sync.json` is a versioned JSON document with a fixed schema:

```json
{
  "zoe_sync_version": 1,
  "generated_at": "2026-02-22T14:00:00Z",
  "user": "jodonnell",
  "changelog": ["last 5 entries as strings"],
  "todo": {
    "active": ["items"],
    "backlog": ["items"]
  },
  "mailbox": {
    "active_threads": ["items"]
  },
  "environment": {
    "os": "...",
    "shell": "...",
    "working_directory": "..."
  }
}
```

JSON is unambiguous. Every AI can parse it. ZOE.md adds one instruction: "If you receive a JSON block tagged `zoe_sync_version`, parse each field by its key and orient accordingly." No markdown ambiguity, no section-header mismatches, no compression artifacts. The version field makes upgrades safe.

### Sub-problem 3 — Write-back without terminal access

Non-Claude AIs produce a structured write-back block at session end:

```json
{
  "zoe_writeback_version": 1,
  "session_end": "2026-02-22T16:00:00Z",
  "changelog_entries": ["- 2026-02-22T16:00:00Z [add]: ..."],
  "mailbox_entries": ["- 2026-02-22T16:00:00Z [context]: ..."]
}
```

Add a script `SCRIPTS/apply_writeback.sh` that accepts this JSON from stdin and appends the entries to the correct files. User runs:

```bash
pbpaste | bash SCRIPTS/apply_writeback.sh
```

One command. The AI outputs the JSON block. The user copies it, pastes it to the terminal. The script validates the version field, appends entries, and commits. Write-back goes from four manual steps to one.

### Fatal Flaw

This design assumes the user's GitHub repo is public (for raw URL access) or that the AI has authenticated GitHub access. Private repos return 404 on raw URLs without a token. Giving an AI a GitHub personal access token is a significant security surface — tokens can be leaked through conversation logs. The user who needs this most (non-technical, using Grok on mobile) is the least likely to know how to scope a read-only token, and the most likely to paste their full-access token by accident. The design is elegant for technical users who already understand GitHub auth, and dangerous for everyone else.

---

## Design 3: Zoe-Lite Read-Only Mode (The Explicit Downgrade)

**One-line summary:** Accept that non-Claude AIs are a degraded mode by design, say so explicitly in ZOE.md, give them a minimal bootstrap path, and make the user's expectation match reality instead of pretending all AIs are equal.

### Core Assumption

The current spec's fundamental problem is a false promise: "works in any AI" implies equivalent capability across AIs, which is architecturally untrue. This design abandons that promise at Level 3 — non-Claude AIs at Level 3 become "Zoe Lite," a defined capability tier with documented limitations. The user knows what they're getting. No expectations are violated.

### Sub-problem 1 — Bootstrap without file access

ZOE.md adds a new section "AI Capability Tiers" above the Sync Up section:

> **Tier A — Terminal AI (Claude Code):** Full read/write access. Canonical Zoe. All features available.
>
> **Tier B — Chat AI with browsing (Grok, ChatGPT with web):** Can fetch your state URL. Read-only. Can produce write-back artifacts for you to apply.
>
> **Tier C — Chat AI without browsing (base Gemini, offline models):** Needs you to paste a sync block. Read-only. Produces write-back artifacts.

The "Sync Up" section becomes tier-aware:

> "When someone says 'sync up': determine your tier. Tier A: read STATE/ files. Tier B: ask for GitHub username, fetch sync URL. Tier C: ask the user to paste their sync block (output of `bash SCRIPTS/new_session.sh`). If they have no block, run First Contact and tell them their current AI tier cannot persist state without a manual step."

Bootstrap is now explicit about what it requires per tier. The user is never surprised that Grok doesn't have their history — they know Grok is Tier B/C before they start.

### Sub-problem 2 — State schema portability

ZOE.md defines a single canonical sync block format with strict section markers, and instructs Zoe to recognize it by header regardless of source:

```
<!-- zoe-sync v1 | tier:[A/B/C] | generated:[TIMESTAMP] -->
## Zoe Sync
**User:** [name] | **Tier:** [A/B/C] | **Generated:** [TIMESTAMP]

### CHANGELOG (last 5)
[entries, one per line, format: `- TIMESTAMP [cat]: description`]

### TODO-ACTIVE
[items, one per line]

### TODO-BACKLOG
[items, one per line]

### MAILBOX-ACTIVE
[items, one per line]

### ENVIRONMENT
[key: value pairs, one per line]
```

The version comment is machine-parseable. The tier field tells the receiving AI what it can write back. ZOE.md adds: "Parse a sync block by its `###` section markers. Trust the tier field. Do not infer capability beyond what the tier declares."

`new_session.sh` is updated to emit this format with the HTML comment header. This is a small patch to an existing script.

### Sub-problem 3 — Write-back without terminal access

Tier B and Tier C AIs are explicitly read-only for state files. ZOE.md states this directly:

> "If you are operating as Tier B or C: you cannot write to STATE/ files. This is by design. At session end, output a write-back block in the canonical format and instruct the user: 'The next time you're in Claude Code, paste this block and say apply writeback.' Claude Code knows how to apply it."

Claude Code's CLAUDE.md adds: "If the user pastes a block starting with `<!-- zoe-writeback -->`, parse it and apply the CHANGELOG and MAILBOX entries before doing anything else. Confirm what was applied."

Write-back is asynchronous by design. It does not require the user to touch a terminal immediately after a Grok session. It accumulates in the write-back block until the next Claude Code session. One tier does the writing for all tiers.

### Fatal Flaw

This design works only if the user actually returns to Claude Code regularly. If the user abandons Claude Code entirely (switches to Grok permanently, or their employer blocks Claude), write-back never happens, and state diverges permanently. The design also requires the user to understand tiers and remember which tier they're in — cognitive overhead that contradicts Zoe's core promise of "just works." The explicit downgrade is honest, but honesty about a bad experience is not the same as fixing the bad experience. A user who reads "Tier C: cannot persist state" may simply stop using Zoe.

---

## Gut Recommendation

Build Design 1 (Paste-First Protocol) with the write-back artifact from Design 3. Design 1 requires the fewest new moving parts — `new_session.sh` already exists, the fix is purely documentation and ZOE.md wording — and adding the explicit tier language from Design 3 sets honest expectations without requiring a new script, a hosted URL, or a JSON schema. Design 2 is the right long-term architecture but introduces a GitHub auth surface that will cause real security incidents for non-technical users before it delivers value; build it only after the paste-first habit is established and the user base proves they want it.
