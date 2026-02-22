# Sync Protocol Gap Analysis

**Author:** Scout
**Date:** 2026-02-22
**Question:** When a user says "sync up" to a fresh Zoe instance on a different AI (e.g., used Claude yesterday, now in Grok), what exactly happens? What breaks? What's missing?

---

## 1. What the Current Spec Says About Sync

### ZOE.md (the universal system prompt)

The sync logic lives in a five-line section:

> When someone says "sync up":
> - If they have a repo: read `STATE/ENVIRONMENT.md` and `STATE/CHANGELOG.md`. Orient. Propose next actions.
> - If they have a context block: read it. Pick up from there.
> - If neither: run First Contact, then offer to set up a repo or write a context block.

That is the complete specification. There is nothing else.

### CLAUDE.md (Claude Code-specific)

The "First Session Check" in CLAUDE.md adds one gate: confirm the user owns their repo (not a clone of the template), then read `STATE/` and get oriented.

The sync state protocol in CLAUDE.md says:
- Authoritative state lives in `STATE/`.
- When syncing, read `STATE/ENVIRONMENT.md` and `STATE/CHANGELOG.md` first.

### SCRIPTS/new_session.sh

There is one script that generates a sync blob — it collects the last 5 changelog entries, active TODO items, open MAILBOX threads, and an environment summary, then prints a paste-ready markdown block. This is the only concrete mechanism for cross-session, cross-AI state transfer.

### What the spec assumes

The spec implicitly assumes one of two situations when "sync up" is said:

1. **The AI can read the repo directly** (Claude Code in the same terminal, where files are accessible). In this case, the AI reads STATE/ files.
2. **The user pastes a context block** that Zoe wrote at the end of a previous session.

Both assumptions collapse when the scenario is: user yesterday used Claude Code (files accessible), now today uses Grok (no file access, no context block, fresh conversation).

---

## 2. What's Actually Missing

### 2.1 No cross-AI handoff protocol exists

`ZOE.md` is the universal system prompt. It specifies what Zoe *is*, not how to *transfer* what Zoe *knows*. The only handoff mechanism in the entire repo is `SCRIPTS/new_session.sh` — a script that:

- Lives on the user's local machine
- Requires the user to run it manually
- Requires the user to remember to run it before switching AIs
- Is never mentioned in `ZOE.md`
- Is never mentioned in the "Sync Up" section of `ZOE.md`
- Is never mentioned in `SETUP.md`'s Step 4 (First sync)

The sync section in `ZOE.md` does not instruct Zoe to ask the user to run `SCRIPTS/new_session.sh`. It does not tell the user this script exists. A Grok instance reading `ZOE.md` has no idea this script exists.

**The gap:** The mechanism for generating a paste-able sync blob (`new_session.sh`) is completely disconnected from the user-facing sync instruction in `ZOE.md`. A user on Grok who says "sync up" gets told by Zoe to paste in `STATE/ENVIRONMENT.md` and `STATE/CHANGELOG.md` — but Grok cannot read those files, the user may not know to open them, and `ZOE.md` gives no explicit instruction to do so.

### 2.2 The "context block" format is undefined for the repo path

The `ZOE.md` "Working Without a Repo" section defines a context block format for the no-repo case:

```
## Zoe Context — [Your Name]
- Name: [name]
- Role / what you do: [what they told you]
- Current focus: [what they're working on]
- Preferences Zoe knows: [anything relevant]
- Last updated: [today's date]
```

This is a conversational summary. It contains no structured state — no changelog, no open TODOs, no MAILBOX threads. It is designed for Level 0-1 users.

For Level 3 users (full repo), there is no defined "context block" format. `new_session.sh` produces one, but:
- It is not called a "context block" anywhere in the spec
- `ZOE.md` does not reference it
- There is no instruction to paste the output of `new_session.sh` when starting in a new AI
- There is no standard schema that Zoe instances are trained to parse

**The gap:** Two different context-passing mechanisms exist (conversational context block vs. `new_session.sh` blob) with no unification. A Grok instance reading `ZOE.md` will attempt to apply the Level 0 context block format to a Level 3 user, discarding all structured state.

### 2.3 CLAUDE.md is Claude-specific and not portable

`CLAUDE.md` is the behavior config that personalizes Zoe for a specific user. It contains `[YOUR NAME]`, `[YOUR TOP PRIORITY]`, and the Core Domains section. This file is the closest thing to a user identity profile in the system.

When a user moves to Grok:
- Grok does not load `CLAUDE.md` automatically
- `ZOE.md` does not instruct any AI to ask for or consume `CLAUDE.md`
- There is no instruction to paste `CLAUDE.md` content into a new AI session
- The user is expected to re-answer the First Contact questions from scratch (or paste a context block)

**The gap:** The personalization layer (`CLAUDE.md`) is tool-locked to Claude Code. Nothing in the sync spec tells a non-Claude AI where the user profile lives or how to retrieve it.

### 2.4 MAILBOX.md is not included in the sync instruction

`ZOE.md` says: "If they have a repo: read `STATE/ENVIRONMENT.md` and `STATE/CHANGELOG.md`."

`STATE/MAILBOX.md` is not mentioned in this instruction. But `MAILBOX.md` is specifically designed for session continuity:

> "Context for future sessions. Why things changed, what to remember, open threads."

`MAILBOX.md` is where reasoning lives — *why* something changed, not just *what* changed. `CHANGELOG.md` is a log of events. Syncing without the MAILBOX means Zoe gets facts without context. This is not a minor omission: `CLAUDE.md` lists the MAILBOX as essential ("after every approved change, append to both files"), but `ZOE.md`'s sync instruction ignores it entirely.

**The gap:** `STATE/MAILBOX.md` and `STATE/TODO.md` are both omitted from the sync instruction in `ZOE.md`, despite being the two most relevant files for picking up active work.

### 2.5 No instruction exists for what a non-file-capable AI should do

When a user says "sync up" to Grok (which has no terminal, no file access, no tool use for the repo), `ZOE.md`'s sync spec gives Zoe no branching logic for "I cannot read the repo, what do I ask the user to provide?"

The section "What Zoe Can Do Without a Terminal" mentions that Zoe can maintain state by asking the user to paste file contents. But this instruction is generic and not connected to the sync protocol. Grok-Zoe will not automatically prompt: "I can't read your repo — please paste the output of `bash SCRIPTS/new_session.sh`."

**The gap:** There is no fallback sync path for non-terminal AIs. The spec says "read STATE/" without addressing that most AI chat interfaces cannot read files.

### 2.6 The sync state is write-only from non-Claude AIs

When Claude Code (with terminal access) makes a change, it appends to `CHANGELOG.md` and `MAILBOX.md`. When Grok makes a change in a chat session, there is no mechanism, instruction, or prompt for Grok to write back to the repo. Work done in Grok evaporates.

**The gap:** State synchronization is one-directional in practice. Read path is broken (see above). Write path does not exist for non-Claude AIs.

---

## 3. The 3 Hardest Sub-Problems Any Solution Must Solve

### Sub-problem 1: Bootstrap without file access

The fundamental problem is that sync requires reading files, but most AI chat interfaces (Grok, ChatGPT, Gemini in base mode) have no file access. The user must manually retrieve and paste the relevant state. But the user does not know what to paste, when to paste it, or that a script exists to generate it.

This is hard because the solution must work for a user who:
- Is in a new AI with no memory of prior instructions
- May not remember to paste anything
- May paste the wrong thing (the wrong file, an outdated context block)
- May be using the AI in a context where copy-paste is cumbersome (mobile, voice)

The bootstrap cannot rely on the AI having access. It must rely on the user having a habit. That habit is not currently taught, prompted, or enforced anywhere in the spec.

### Sub-problem 2: State schema portability

`new_session.sh` produces a markdown blob. Zoe's response to that blob is undefined. There is no instruction in `ZOE.md` that says "if you receive a block that looks like this, parse it this way." Different AI instances may interpret the same blob differently — one may treat it as context to summarize, another may parse it literally, another may ignore sections it doesn't understand.

This is hard because:
- You cannot train the AI to parse a specific format without including parsing instructions in `ZOE.md`
- Adding verbose parsing instructions to `ZOE.md` makes the system prompt unwieldy
- The format itself may need to evolve, but the AI's parsing instructions are static in the prompt

Any solution must define a schema and embed enough parsing rules in `ZOE.md` that any AI (Grok, ChatGPT, Claude) will handle the state blob consistently.

### Sub-problem 3: Write-back without terminal access

Even if a non-Claude AI successfully reads state at session start, it has no way to write state back at session end. Zoe in Grok can draft a CHANGELOG entry but cannot append it to the file. The user must manually copy the output, open the file, paste it, and commit. This requires four manual steps the user is unlikely to take.

This is hard because:
- You cannot give Grok terminal access
- You cannot enforce a write-back habit through prompting alone
- If write-back fails, the next AI session starts from stale state — and the staleness is invisible
- The longer Grok is used without write-back, the more diverged the repo state becomes from actual reality

Any solution must either (a) make the write-back so low-friction it actually happens, or (b) accept that non-Claude AIs are read-only and design the state model around that constraint explicitly.

---

## 4. What You'd Need to Know to Solve These

### To solve Sub-problem 1 (bootstrap without file access):

- What is the minimum viable state payload that lets Zoe orient in under 60 seconds?
- Should `new_session.sh` be the canonical mechanism, or should there be a GitHub-hosted URL that always returns current state (solving mobile/paste friction)?
- What is the trigger for the user to run `new_session.sh`? Is it at session end (current implicit design) or session start? Neither is currently specified.
- Should `ZOE.md` contain explicit instructions like "if I cannot read files, ask the user to run `bash SCRIPTS/new_session.sh` and paste the output"?

### To solve Sub-problem 2 (state schema portability):

- What fields are required in a sync blob vs. optional?
- What is the canonical section structure that every Zoe instance (regardless of AI) must recognize?
- Should the sync blob be versioned (e.g., `<!-- zoe-sync v1 -->`) so Zoe can detect format changes?
- Does `ZOE.md` need a "Sync Block Format" section that defines parsing behavior?

### To solve Sub-problem 3 (write-back without terminal access):

- Is the accepted design that non-Claude AIs are read-only Zoe instances? If so, that should be stated explicitly rather than implied.
- If write-back is required, what is the exact UX? (e.g., "At the end of every session, Zoe outputs a CHANGELOG block — user pastes it into the repo")
- Should there be a GitHub Actions workflow or webhook that accepts state updates from outside the terminal?
- What happens to state produced during a Grok session that never gets written back — is it lost, or should it be treated as ephemeral by design?

### Cross-cutting question:

Is the Level 3 (full repo) experience designed for Claude Code specifically, with other AIs treated as degraded Level 0-1 fallbacks? If yes, that design choice must be made explicit in `ZOE.md` so users are not surprised when Grok-Zoe behaves differently than Claude-Zoe. If no — if the intent is true AI-agnosticism at Level 3 — then the sync protocol needs a complete rewrite.

---

*The sync section in `ZOE.md` is five lines for a problem that requires twenty. Everything else in the system assumes Claude Code with terminal access. The gap between the promise (works in any AI) and the reality (state transfer only works with a terminal) is the core problem this debate must resolve.*
