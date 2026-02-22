# Sync Protocol Design Proposals — Haiku Architect

**Author:** Architect (Haiku 4.5)
**Date:** 2026-02-22
**Input:** Scout's gap analysis + Sonnet's three designs
**Question:** Which design actually solves bootstrap, schema, and write-back without lying to the user?

---

## Where I Disagree with Sonnet

Sonnet's three designs are competent but each hedges at the critical moment:

1. **Design 1 (Paste-First):** Honest about the problem but relies entirely on a habit most users won't form. Sonnet even admits this: "the habit is the load-bearing structure, and habits are fragile."
2. **Design 2 (State-as-URL):** Technically clean but punts the real pain to GitHub auth. Private repos + token management is friction that kills adoption for non-technical users.
3. **Design 3 (Tier-Based Downgrade):** Honest about limits, but "accept that you lose state" is not a solution — it's giving up. A user who reads "Tier C: cannot persist state" doesn't keep trying.

All three assume the user will *actively manage* state transitions. They won't. Users will close Claude Code, open Grok, say "sync up," and expect it to work.

I'm proposing three different designs that frontload different trade-offs.

---

## Design 1: Sync Block Generator — Ambient State Capture (The Lazy-Friendly Path)

**One-line summary:** Generate a minimal sync block automatically at session end (or on a git hook), store it in an uncommitted `.zoe-sync` file that the user copies once, and reuse it across multiple sessions.

### Core Assumption

Users will not run a script between sessions. But users *will* let a tool run automatically when they close a terminal or commit code. The sync block doesn't need to be regenerated every time — it needs to be *available* with minimal friction. A file that lives in the repo but stays out of git (in `.gitignore`) can be copied/pasted repeatedly without cluttering the history.

### Sub-problem 1 — Bootstrap without file access

Add a git hook that runs `new_session.sh` after any commit and writes the output to `.zoe-sync` (uncommitted). ZOE.md changes to:

> "If I can't read your repo: ask 'Do you have a `.zoe-sync` file nearby? Copy and paste its contents.' If they say 'I don't have it,' tell them: 'No problem. Here's what to do once: in Claude Code, run `git -C /path/to/zoe log --oneline -1` and tell me you just committed something. That sets up automatic sync blocks. Next time you switch AIs, just copy the `.zoe-sync` file that appears.' If they can't do that, fall back to First Contact."

Bootstrap becomes: (1) AI reads files, (2) user copies `.zoe-sync` if it exists, (3) First Contact.

The user only has to understand *one thing*: a file appears after you commit. Copy it when you switch AIs.

### Sub-problem 2 — State schema portability

Reuse Sonnet's canonical format from Design 3 (strict `###` section markers + HTML comment versioning). The `.zoe-sync` file is always `new_session.sh` output in that format. No new schema.

ZOE.md adds one instruction: "Parse by `###` headers. If the block starts with `<!-- zoe-sync`, treat it as state."

No ambiguity. No compression artifacts. Every AI parses it the same way.

### Sub-problem 3 — Write-back without terminal access

Chat AIs cannot write. So they don't. ZOE.md explicitly states:

> "If you are operating in a chat interface (Grok, ChatGPT, Gemini): you cannot write back. At session end, output a standardized write-back block like this:
> ```
> ## Write-Back for Claude Code
> Paste this at the start of your next Claude Code session:
>
> cat >> STATE/CHANGELOG.md << 'EOF'
> - 2026-02-22T14:30:00Z [state]: [summary of work]
> EOF
> ```
> The user will apply it in Claude Code, the canonical AI."

Write-back is not automatic. It's manual, but *formalized*. The user knows they have to do it, and exactly how.

### Fatal Flaw

If the user never commits anything in Claude Code (they just use it to ask questions), `.zoe-sync` never gets created. The hook sits dormant. Users working on branches that never get committed won't have a sync block ready. The design only works if the user has a git-aware workflow to begin with. For Level 0-1 users, this adds invisible infrastructure that does nothing.

### Gut Check

Would a non-technical user actually do this? Only if they think of `.zoe-sync` as a "download my state" button that appears automatically. For users who understand "commits create sync blocks," this is brilliant. For users who never commit (and there are some), it's worse than Sonnet's paste-first design because there's *nothing to paste*.

---

## Design 2: Gated Model Capability Declaration (The Honest Tier System + Aggressive Simplification)

**One-line summary:** Declare upfront which AIs are canonical and which are fallback, eliminate the false promise of model-agnosticism, and ruthlessly cut features for non-canonical AIs.

### Core Assumption

The current design fails because it tries to treat all AIs as equal and fails at all of them. The fix is not to make them equal — it's to declare them *unequal* and optimize each tier separately. Claude Code gets read/write and gets the full Zoe. Chat AIs get read-only and get a lightweight mode. This is honest. It's also faster.

### Sub-problem 1 — Bootstrap without file access

ZOE.md adds a new top section:

> "**Which Zoe are you?**
>
> **Zoe Full** (Claude Code with terminal access): Read and write your state files. Full system. Recommended.
>
> **Zoe Lite** (Chat interface: Grok, ChatGPT, Gemini): Read-only. You can load your state and work in the chat, but you can't write back. At session end, I'll draft CHANGELOG entries for you to apply manually in Claude Code."

Then the "Sync Up" section becomes tier-specific:

> "**Zoe Full (Claude Code):** `sync up` → I read STATE/ directly and orient.
>
> **Zoe Lite (Chat):** `sync up` → Paste the `.zoe-sync` file from your last Claude Code session (or run `new_session.sh` in a terminal and paste the output)."

No pretense. No "works in any AI." Clear expectations.

### Sub-problem 2 — State schema portability

Use Sonnet's strict `###` format. It's machine-parseable and unambiguous.

But for Zoe Lite, *strip down* the sync block:

- Last 2 changelog entries (not 5)
- "Active" TODO items only (no backlog noise)
- No MAILBOX at all (too much context for chat)
- 2-3 environment variables (OS, shell, working dir)

Sonnet and Scout both said: "2KB of useful state is better than 10KB." Zoe Lite gets a 2KB sync block. Claude Code gets the full thing.

### Sub-problem 3 — Write-back without terminal access

Zoe Lite outputs a write-back block at session end. User copies it. Next time in Claude Code, they paste it. CLAUDE.md includes:

> "If the user pastes a block starting with `<!-- zoe-writeback`, parse it and apply the CHANGELOG entries before doing anything else. Say what you applied. Then proceed."

Write-back is async and manual, but it's *named*. The user knows it's coming.

For Zoe Full (Claude Code), write-back is automatic — append to CHANGELOG and MAILBOX as usual.

### Fatal Flaw

This design abandons the "any AI" promise entirely. It says: "Claude Code is the canonical Zoe. Everything else is a degraded mode." Some users will read that and think Zoe is locked to Claude Code, so they won't even try Grok. The design is honest, but honesty without context can read as gatekeeping. Also, if a user starts in Grok (because they don't have Claude Code access), they're immediately second-class. No on-ramp.

### Gut Check

Would a non-technical user actually do this? They'll read "Zoe Lite" and think it's a cheaper version. They might not understand that Lite == "read your files but can't save changes." The naming itself is confusing. But the mechanism is simple: paste `.zoe-sync`, work in chat, copy-paste a write-back block at the end. That's actually less friction than Sonnet's Design 1.

---

## Design 3: Passive Sync — Zero Friction Bootstrap, Constrained Write (The Pragmatist's Path)

**One-line summary:** Assume users will paste their GitHub username (or repo name) at session start; Zoe fetches state automatically if possible, fails gracefully if not, and all AIs acknowledge they cannot persist state without manual intervention.

### Core Assumption

The real problem is *not* parsing state — both Scout and Sonnet's designs handle that. The real problem is *knowing what state to ask for*. Users don't know to run `new_session.sh`. They don't know a `.zoe-sync` file exists. But users *do* know their GitHub username. So start there.

Also: accept that write-back is a *ritual*, not automatic. Users in chat AIs will manually apply write-back blocks in Claude Code. Users in Claude Code will auto-save. Both are fine — they're just different.

### Sub-problem 1 — Bootstrap without file access

ZOE.md changes "Sync Up" to:

> "When you say 'sync up,' I'll ask: 'What's your GitHub username and repo name?' Then:
>
> - If I can fetch URLs: I'll grab your latest state from `https://raw.githubusercontent.com/[user]/zoe/main/.zoe-sync`.
> - If I can't: Ask you to paste that file (copy it from your terminal or from GitHub in a browser).
> - If you have nothing: First Contact."

Bootstrap is now: (1) AI fetches by URL, (2) user pastes from GitHub web UI, (3) First Contact.

The user only has to remember their username, not a script.

But `.zoe-sync` still has to exist. So CLAUDE.md gets:

> "At session end, always run `bash SCRIPTS/new_session.sh > /tmp/zoe-sync-$TIMESTAMP.md` and update `.zoe-sync` with `cp /tmp/zoe-sync-$TIMESTAMP.md .zoe-sync`. Commit STATE/ changes, but leave `.zoe-sync` uncommitted so the next session's Zoe can fetch it fresh."

### Sub-problem 2 — State schema portability

Same canonical format (strict `###` headers + HTML comment versioning). Unambiguous parsing.

For users with URLs: fetch once, parse once. For users pasting: clipboard is clipboard. No schema ambiguity.

### Sub-problem 3 — Write-back without terminal access

Chat AIs output a write-back block at session end:

```
## To apply this in Claude Code:
Paste this block at the start of your next Claude Code session:
cat >> STATE/CHANGELOG.md << 'EOF'
- 2026-02-22T14:30:00Z [state]: [summary]
EOF
cat >> STATE/MAILBOX.md << 'EOF'
- 2026-02-22T14:30:00Z [context]: [details]
EOF
```

User copies, switches to Claude Code, pastes, runs. Claude Code applies it, updates `.zoe-sync`, and next session in chat AIs gets the fresh state.

Claude Code automates this: after every edit, regenerate `.zoe-sync`.

### Fatal Flaw

This design still requires the user to maintain `.zoe-sync` manually in Claude Code. If the user forgets to run the script, `.zoe-sync` gets stale, and the next chat session loads old state. Also, this design assumes users have their repo public (or have GitHub browsing access in chat AIs). Private repos will fail silently at step (1) and degrade to First Contact — which is honest but not great UX.

### Gut Check

Would a non-technical user actually do this? Yes, if they remember their GitHub username. "Tell me your GitHub username" is simpler than "run this script and paste the output." But the `.zoe-sync` file still has to be maintained, and that's still manual for Claude Code users. It's pragmatic but not elegant.

---

## My Recommendation

Build **Design 1 (Sync Block Generator — Ambient State Capture)** with a fallback to **Design 3 (Passive Sync) for users without git-aware workflows**.

Design 1 is the best for people who already use git and commit frequently (which is most Zoe users). The automatic `.zoe-sync` file is zero-friction once the hook is installed. Design 3's GitHub username approach is a safety valve for users who don't commit often — they can paste a URL or fetch manually.

**Why not Design 2 (Gated Model Capability)?** It's the most honest design, but it's also the one that will cause adoption to plateau. Users read "Lite" and assume they're getting a toy. The overhead of *naming* the degradation doesn't actually reduce it — it just makes it visible. Better to make the user-facing experience transparent (Designs 1 and 3) and let the docs explain the consequences, rather than gate users at the auth layer.

Also: **reject Sonnet's Design 2 (State-as-URL) entirely.** The GitHub token surface is real and will cause security issues. Users will paste full-access tokens. Don't build infrastructure that incentivizes that.

---

## Immediate Patches to ZOE.md (Required for Any Design)

Regardless of which design wins:

1. **Kill the hedging in the current Sync section.** Change from:
   > "If you cannot read the repo directly (e.g., Grok, ChatGPT, Gemini in chat): ask this immediately..."

   To something explicit about which AIs can do what.

2. **Add a "Sync Block Format" section** that defines `<!-- zoe-sync-v1 -->` markers and parsing rules by `###` headers. Make it unambiguous.

3. **Update CLAUDE.md's Session-End Nudge** to say: "If you're moving to a chat interface, `.zoe-sync` will be available on your next commit. Copy it and paste it at the start of that conversation." (Not: "run the script" — the hook does that.)

4. **Remove the pretense of write-back for chat AIs.** Replace with: "At session end, I'll output a write-back block you can apply in Claude Code next time. This is how work in chat AIs gets recorded."

---

## Why Sonnet's Designs Are Not Wrong — Just Incomplete

Sonnet's Design 1 (Paste-First) is *correct for disciplined users*. It just doesn't handle the undisciplined ones.

Sonnet's Design 3 (Tier-Based) is *correct in spirit* (Claude Code is canonical). It just markets it badly. Rename "Tier B/C" to "Zoe Lite" or "Chat Mode" and it becomes more palatable.

I'm proposing refinements, not rejections. But the hard truth is: **no design works for all users equally.** Design 1 works if users commit code. Design 3 works if users remember their GitHub username. Both are reasonable assumptions. Building for both (Design 1 as primary, Design 3 as fallback) gets you to 90% of the user base.

---

*The syncing problem is not technical — it's behavioral. The solution is to make the common case (terminal-capable user, frequent commits) effortless, and the fallback case (chat-only, sporadic work) explicit and manageable.*

