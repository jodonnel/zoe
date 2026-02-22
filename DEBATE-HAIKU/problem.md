# Sync Protocol Gap Analysis — Haiku Scout

**Author:** Scout (Haiku 4.5)
**Date:** 2026-02-22
**Question:** When a user says "sync up" to a fresh Zoe instance on a different AI (e.g., Claude Code yesterday, Grok today), what exactly happens? What breaks? What's missing?

---

## Executive Summary

The Sonnet Scout's analysis is accurate. But I'll say it harder: **the sync protocol doesn't exist for non-Claude AIs. It's a missing feature, not a gap.**

When you switch from Claude Code to Grok and say "sync up," the current spec tells Grok to read files Grok cannot access, and then implicitly wait for a context block the user was never told to generate. That's not a "fallback path" — that's a silent failure mode.

The core problem: ZOE.md promises model-agnosticism but delivers Claude-specific behavior. The system is designed around terminal access that most AIs don't have.

---

## 1. What Actually Breaks (Concrete)

### 1.1 The immediate failure: "Read the files"

When a user on Grok says "sync up," here's what ZOE.md tells Grok to do:

> "If you can read the repo directly... read `STATE/ENVIRONMENT.md`, `STATE/CHANGELOG.md`, `STATE/TODO.md`, and `STATE/MAILBOX.md`."

Grok cannot read files. Grok has no terminal, no file system access, no tool use for repos. **This instruction is dead code for Grok.**

Grok then hits the else clause:

> "If they have a sync block from your last session... ask them to paste it. If they can't, ask them to run `bash SCRIPTS/new_session.sh`."

**Problem 1:** The user was never told that `SCRIPTS/new_session.sh` exists. It's not mentioned in ZOE.md. It's not mentioned in CLAUDE.md's "Session-End Nudge." It's mentioned *only* in one sentence of ZOE.md's sync section, as a question Zoe should ask. That sentence assumes the user has a terminal open *right now*.

**Problem 2:** The user is now on Grok. They have to context-switch to a terminal, navigate to their zoe repo, run the script, copy the output, switch back to Grok, and paste it. Most users will not do this. They'll just start asking Grok questions.

**Result:** Grok-Zoe defaults to First Contact (the three identity questions), erasing all prior context.

### 1.2 The second failure: "Paste a sync block"

Even if the user runs `new_session.sh` and pastes the output, the spec doesn't tell Grok how to parse it.

ZOE.md says:

> "If they paste a sync block... parse each `###` section by its heading. Treat it as authoritative state."

But `new_session.sh` output starts with `<!-- zoe-sync-v1 | tier:A | generated:2026-02-22T14:30:00Z -->`. There is no parsing schema. There is no instruction for how Grok should extract the changelog, or which fields matter, or what to ignore.

Different AIs will interpret the markdown blob differently. Claude Code (trained on markdown + code) might parse it well. Grok, trained differently, might treat it as prose and summarize it. ChatGPT might extract the sections correctly but weight them wrong.

**Result:** Even if the user does the work to paste the block, Grok might misinterpret it.

### 1.3 The third failure: Write-back

After a Grok session where you've made real decisions (added TODOs, closed a mailbox thread, made a deployment), there is no mechanism for Grok to write those changes back to the repo.

Grok can *draft* a CHANGELOG entry. But Grok cannot append it to the file. The user has to:

1. Copy the CHANGELOG entry Grok drafts
2. Switch to a terminal
3. Open `STATE/CHANGELOG.md`
4. Append the entry
5. Commit it
6. Switch back to Grok

**This does not happen.** Users will do the work in Grok, close the tab, and come back to Claude Code tomorrow with stale state.

**Result:** Work done in Grok is invisible to Claude Code. The next time you sync in Claude Code, you get state from yesterday because Grok never wrote back.

---

## 2. What the Sonnet Scout Got Right (and I Won't Repeat)

Sonnet correctly identified:

1. **The gap between spec and tooling:** `new_session.sh` exists but isn't integrated into the user-facing sync instruction.
2. **The missing schema:** No defined format for the sync block that all AIs are trained to parse.
3. **MAILBOX.md omission:** It's left out of the sync instruction despite being essential for continuity.
4. **CLAUDE.md tool-lock:** It's only loaded by Claude Code, not accessible to other AIs.
5. **The three hard sub-problems:** Bootstrap without file access, state schema portability, write-back without terminal access. These are real and unsolved.

I agree with all of that. Sonnet's framing is accurate.

---

## 3. Where I Disagree (or Sharpen)

### 3.1 Sonnet: "Two different context-passing mechanisms"

Sonnet says there's the Level 0-1 context block (conversational) and the Level 3 context block (`new_session.sh` output), and they're not unified.

**I'd push harder:** They're not just unrelated — they're incompatible. The Level 0-1 block is *designed* to be summarized by a human. The Level 3 block is *designed* to be parsed programmatically by Zoe. Asking Grok to use the same code path for both is asking Grok to either under-utilize Level 3 state or over-parse Level 0 state. The current spec doesn't give Grok a way to distinguish between them.

### 3.2 Sonnet: "Read path is broken. Write path does not exist."

True, but incomplete. The real problem is **asymmetry.**

Claude Code has bidirectional state sync: reads STATE/ at session start, writes to CHANGELOG/MAILBOX at session end. The system is designed assuming a stateful, terminal-capable agent.

Grok (and ChatGPT, and Gemini) are stateless chat interfaces. They have no session lifecycle, no persistent working directory, no natural place to write state. Even if we solved the read path (give Grok the state at session start), the write path is fundamentally mismatched to how chat UIs work.

**The asymmetry is: Claude Code is designed as a system component. Chat AIs are designed as conversation endpoints.**

### 3.3 Sonnet's "cross-cutting question" is the right one, but framed backward.

Sonnet asks: "Is Level 3 designed for Claude Code specifically, with other AIs treated as degraded Level 0-1 fallbacks?"

**The answer is obviously yes.** The code and the prompt are both Claude-centric. But the spec claims model-agnosticism.

**What Sonnet missed:** This is not a bug — it might be the right design choice. Claude Code *should* be the canonical, stateful Zoe. Other AIs *should* be fallbacks. But if that's the design, say it explicitly. Don't claim "works in any AI" and then deliver "works great in Claude Code, and Grok gets a degraded mode."

---

## 4. What Actually Needs to Exist (Opinionated)

I'm cutting the hedging. Here's what I think must happen:

### 4.1 Kill the implicit assumption

**Change in ZOE.md's sync section:**

Current (implicit Claude-centric):
> "If you can read the repo directly, read STATE/. If not, ask the user for a sync block."

Better (explicit model-agnosticism):
> "**If terminal-capable (e.g., Claude Code in a terminal):** Read STATE/ directly. **If not (e.g., chat interface):** Ask the user to paste the output of `bash SCRIPTS/new_session.sh`. Do not attempt to read files. Do not fall back to First Contact unless the user has nothing to paste.**"

This removes the implied capability assumption that breaks on Grok.

### 4.2 Make `new_session.sh` non-optional

The script is essential. So:

1. **Advertise it in ZOE.md:** Add a concrete instruction: "To prepare for switching to a different AI, run `bash SCRIPTS/new_session.sh` in your Zoe repo and save the output."
2. **Mention it in CLAUDE.md's Session-End Nudge:** Change "run the script" from optional flavor text to a hardcoded recommendation when wrapping up a session.
3. **Formalize the output as a "Sync Block":** It's not a context block (that's Level 0). It's a Sync Block. Name it. Version it (`<!-- zoe-sync-v1 -->`). Embed parsing instructions in ZOE.md that say: "A sync block starts with `<!-- zoe-sync-v1` and contains sections separated by `---`. Extract each `###` section by heading."

### 4.3 Accept that write-back is not a solvable problem for chat AIs

Here's the hard truth: **Chat AIs cannot write back to repos reliably.**

So the design should be:

- Claude Code: **Read/write.** Bidirectional sync. STATE/ is canonical.
- Chat AIs: **Read-only.** Sync in at session start from a pasted Sync Block. Work in the chat. At session end, user manually copies the CHANGELOG entry Zoe drafts and pastes it into STATE/. Or doesn't — and accepts the work is ephemeral.

**Make this explicit in ZOE.md:** "Work done in chat AIs is not automatically saved to your repo. If you want to record it, copy the CHANGELOG entry that Zoe outputs and paste it into STATE/CHANGELOG.md."

This is honest. It's a constraint, not a bug.

### 4.4 Remove MAILBOX from the required sync state

Sonnet correctly points out MAILBOX is omitted from ZOE.md's sync instruction. I'd go further: **cut it.**

Here's why: MAILBOX is designed for Claude Code (terminal-capable, can read/write files at any time). For chat AIs, it's noise. If a chat AI can only read state at session start, forcing it to digest the entire MAILBOX is cognitive overload.

Instead:

- **MAILBOX stays.** Claude Code continues to use it for detailed reasoning.
- **Sync block includes only the last 3-5 MAILBOX entries**, not all of them. Tag them as "context" not "authoritative."
- **ZOE.md sync instruction:** "For orientation, read the recent changelog and mailbox threads. These provide context. Your working state is in TODO and ENVIRONMENT."

### 4.5 Reduce the sync block size

`new_session.sh` currently outputs last 5 changelog entries, all TODO sections, all open MAILBOX threads, and environment summary. For chat AIs, that's too much context.

**Trim it to:**

- Last 3 changelog entries (not 5)
- Only "Active" TODO items (not backlog)
- Last 2 mailbox threads (not all)
- Minimal environment (OS, shell, maybe one tool version)

**Reasoning:** Chat AIs have token limits and attention budgets. A 2KB sync block is useful. A 10KB sync block will be summarized and neutered by the AI before processing.

---

## 5. What I'd Actually Keep (Brutal Honesty)

This framework is good:

- **The identity layer (ZOE.md + CLAUDE.md)** — Tone, lineage, hard rules. These transcend the AI model.
- **The STATE/ structure** — Changelog, TODO, MAILBOX, ENVIRONMENT. These are the right abstraction.
- **The script (`new_session.sh`)** — It's a good mechanism, just invisible.
- **The context block format for Level 0-1** — Lightweight, conversational, works without infrastructure.

What I'd rebuild:

- **The sync protocol** — From implicit and broken to explicit and honest about limits.
- **The model-agnosticism promise** — From false to true (or drop it and be Claude-first).

What I'd cut:

- **The pretense that MAILBOX is sync-essential** — It's nice-to-have, not need-to-have for chat AIs.
- **The implicit "ask the user to paste a context block without telling them how to generate it"** — Either teach the user to run the script, or own that sync is broken.
- **The five-line sync section in ZOE.md** — It needs to be 20+ lines if it's going to handle all the cases it claims to handle.

---

## 6. The Hardest Problem (Unsolved)

All of the above solves the mechanics. But the real gap is **habit formation.**

Even if the spec says "run `bash SCRIPTS/new_session.sh` before switching to a different AI," most users won't remember. They'll:

1. Close Claude Code
2. Open a web chat
3. Say "sync up"
4. Hit a wall when Zoe asks for a sync block

The specification is necessary but not sufficient. The UX has to make it *obvious* and *frictionless* to generate and paste a sync block. Right now it's neither.

**Possible solutions:**

- GitHub Actions: Store the latest sync block in a public endpoint (e.g., `raw.githubusercontent.com/[user]/zoe/main/.zoe-sync-latest.md`). Zoe in chat AIs can ask: "Want me to fetch the latest sync from your repo?" and provide a one-click link.
- Session-end automation: `new_session.sh` output could be copied to clipboard automatically (`| xclip`), with a prompt: "Run this after your session. The sync block is on your clipboard."
- Browser extension or IDE plugin: Integrates with Zoe repo, makes `new_session.sh` a one-click button.

None of these are in the current spec. **This is the unfilled gap that breaks the user's workflow.**

---

## 7. Verdict: Do You Agree with Sonnet?

**Yes, with amendments:**

1. **Sonnet's core diagnosis is right.** The sync protocol is broken for non-Claude AIs.
2. **Sonnet's sub-problems are real and hard.** Bootstrap, schema, write-back.
3. **Where I push further:** The problem is not just under-specified — it's misnamed. This is not a "fallback path." This is a **missing feature** that the spec claims exists but doesn't.
4. **What Sonnet could have cut:** Some of the "what would you need to know" questions are open-ended. The answers are in the design choices above.

**What I'd do:** Rebuild the sync section with explicit branches for terminal-capable vs. chat-interface AIs. Name the gaps. Make the constraints visible. Stop claiming model-agnosticism without delivering it.

---

*The gap is not that the system is over-complicated. The gap is that the spec is dishonest about what it can do.*
