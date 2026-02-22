# Critique: Attacking the Proposals (Haiku Round)

**Author:** Critic
**Date:** 2026-02-22
**Input:** Scout's gap analysis, Architect's three designs, Sonnet Critic's recommendation, Jim's direct correction

**Jim's correction (verbatim):** "The 'works in any AI' is true. It works to the extent that it has integrated capabilities, but even if those are strictly limited, like in GPT, it has been able to build git and apps, same as you."

---

## Preface: Jim's Correction Reframes Everything

Jim's statement kills the escape hatch all three Haiku proposals were silently using. None of them can hide behind "well, non-Claude AIs are just lesser Zoes." GPT with minimal tools has built git repos and deployed applications. Zoe's promise — "works in any AI" — is not aspirational marketing. It is Jim's lived experience. The system either delivers that promise across all environments, or the problem is a *wiring failure*, not a capability failure.

This changes what we attack.

---

## Attack 1: Haiku Architect's Design 1 (Sync Block Generator — Ambient State Capture)

### What it gets right

Design 1 refuses to invent new infrastructure. It takes the existing asset — `new_session.sh`, which already exists and already works — and makes it visible by wiring it into ZOE.md's sync instruction. The `.zoe-sync` file pattern is clever: it lives in `.gitignore`, stays uncommitted, and becomes the single artifact that moves between sessions. The schema (strict `###` headers with `<!-- zoe-sync-v1 -->` markers) is minimal, unambiguous, and parseable by any AI without training.

The write-back block as a formatted shell heredoc is the right level of realism: the user copies it, switches to Claude Code, and pastes it. No pretense that chat AIs can write to repos. It is honest about asymmetry.

### What it gets wrong

**Fatal flaw: the habit is load-bearing, and Architect knows this but doesn't solve it.** Design 1 depends entirely on the user running `new_session.sh` at session *end* in Claude Code, before they know they'll switch AIs. Humans do not have this foresight. Session end = task complete = tab closed. The script is invisible. The user arrives at Grok with no artifact.

When that happens, Design 1 collapses to First Contact. Not a graceful degradation — the same broken experience that exists today, just documented more clearly.

**Second problem: timing inversion.** ZOE.md is read *by Zoe*, not the user. If the instruction to "run `new_session.sh`" only lives in ZOE.md's self-checklist, then Zoe delivers that message *at the end of a Grok session*, when the user is done and closing the tab. But the user *needs* that message *at the start of a Claude Code session*, when they are about to work. The prompt arrives too late to shape behavior.

**Third problem (subtle): no fallback path.** If `.zoe-sync` doesn't exist when the user switches to Grok, Design 1 asks them to "run the script and paste." But the user is now *in Grok*. They have to context-switch to a terminal, remember the script path, run it, come back. That friction is the entire problem Design 1 was supposed to solve. It just defers it to the failure case.

**Jim's correction makes this worse.** If GPT has built git repos using read-only access + manual write-back, then Design 1 is not sufficient. The user might be productive in Grok *for hours* without the sync block. That's not a "fallback" — that's a failure to maintain the promise. Grok-Zoe should start with the state, not collapse to First Contact and hope the user re-explains everything.

---

## Attack 2: Haiku Architect's Design 2 (Gated Model Capability Declaration)

### What it gets right

Design 2 explicitly refuses the "works in any AI" promise and replaces it with tier language: Zoe Full (Claude Code) is real; Zoe Lite (chat) is read-only. This is honest about asymmetry. The write-back model is auditable and requires no new automation. The instruction is concrete: if chat AIs produce a `<!-- zoe-writeback -->` block, Claude Code applies it next time.

### What it gets wrong

**Fatal flaw: Jim directly contradicts its core assumption.** Design 2 is built on the premise that "works in any AI" is a false promise that should be corrected with transparency. Jim says it is not false. GPT has done the work. The solution pattern (declare tier A as "real" and tier B/C as "degraded") is therefore attacking the wrong problem.

Worse, the tier framing creates a *ceiling* that the actual capability does not have. A user who reads "Tier C: cannot persist state without manual intervention" will conclude Grok-Zoe is not for serious work. But Jim's experience proves Grok-Zoe *is* for serious work. The tier label becomes a false negative that teaches the user to expect less before they've tried anything.

**Second problem: terminal dependency assumption.** Design 2 assumes the user will eventually return to Claude Code. "Write-back artifact sits in clipboard until Claude Code appears." But what if the user switches to Grok permanently? What if their employer blocks Claude? What if they simply prefer another tool? Design 2 calls this a constraint. Jim's "works in any AI" says this is an unacceptable assumption — the system must work without a guaranteed return to any single AI.

**Third problem: self-contradiction in the spec.** ZOE.md says: "You work in ChatGPT, Claude, Grok, Gemini, or anything else. The user picks the best tool. You adapt." Design 2 says: "You are Tier C in Gemini. You are read-only. You cannot persist state." These two statements cannot coexist. Zoe cannot simultaneously adapt to any AI and be explicitly degraded in specific AIs. One has to give. Jim's correction says the system prompt wins, which means Design 2's tier framing is incompatible with the spec.

**Fourth problem: the tier labeling kills adoption.** Users do not read tier descriptions and understand their implications. They read the label and make a decision: "Lite" sounds cheap. They do not try it. Design 2 solves a real problem (asymmetry between Claude Code and chat) but solves it in a way that discourages use of the very thing it is supposed to support.

---

## Attack 3: Haiku Architect's Design 3 (Passive Sync — Zero Friction Bootstrap)

### What it gets right

Design 3 correctly identifies that friction is not in "paste a block" but in "know what block to paste and have it available." A GitHub username is easier to remember than a script name. Fetching `.zoe-sync` from a public URL is cleaner than asking for a paste. The `apply_writeback.sh` script reduces write-back from four manual steps to one. For technical users with public repos, this is architecturally clean.

### What it gets wrong

**Fatal flaw: new infrastructure before the wiring is fixed.** Scout and Architect both identified that `new_session.sh` exists but is not wired into ZOE.md. Design 3 does not fix the wiring. Instead, it builds on top of it: `push_state.sh`, `apply_writeback.sh`, `STATE/sync.json`, a git hook, a published URL, and GitHub auth. Before you solve "user doesn't know to run `new_session.sh`," you cannot build infrastructure that depends on `new_session.sh` running reliably.

**Second problem: silent failure mode.** If `push_state.sh` fails silently (network down, hook not installed, permission error, GitHub unresponsive), the URL returns stale state. The user fetches it. Grok-Zoe orients against state from yesterday. No warning. No error flag. This is worse than a missing sync block — at least a missing block forces First Contact, which is honest. A stale URL gives false confidence.

**Third problem: not universally reachable.** Design 3 solves bootstrap for "Tier B" AIs that can fetch URLs. It does nothing for "Tier C" AIs (offline models, enterprise-firewalled AIs, mobile chat, air-gapped systems). Jim's correction says we cannot accept solutions that work for some AIs and not others. A URL mechanism fails the "any AI" test by definition.

**Fourth problem: GitHub auth is a security surface.** Architect noted this in the fatal flaw, but underestimated it. Users will paste PATs (personal access tokens) into chat AIs to make private repos work. Chat histories are logged. Tokens get leaked. This is not a hypothetical. This is what happens at scale.

**Fifth problem: it still requires the user to maintain `.zoe-sync` in Claude Code.** Design 3 has Zoe auto-publish via git hook. But if the hook fails, or the user forgets to commit, or works on a branch that never gets committed, `.zoe-sync` is stale or missing. The sync block *still* has to be manually maintained. Design 3 did not eliminate the habit — it distributed it across two systems.

---

## Attack 4: Sonnet Critic's Recommendation

Sonnet recommends: "Build Design 1 with one change — invert the session-end prompt into a session-start prompt."

Sonnet's change is an improvement. The shift from "user runs script before leaving" to "Zoe asks for script output when they arrive" is real progress. Prompts are more reliable than habits.

**But it is not sufficient.** Sonnet's change solves the *timing* problem (the prompt arrives when needed). It does not solve the *availability* problem. When Zoe asks "Do you have a sync block or can you run the script?" the user is in Grok with no terminal open. If they say "I can run it," they have to context-switch, navigate to their repo, find the script, run it, come back. This friction is still the entire problem.

Sonnet's recommendation also relies on the assumption that the user *can* open a terminal. But Zoe is designed to work in mobile chat, web chat, offline models. Not all Zoe users have a terminal open. Not all can open one. The fallback "if you can't run the script, do First Contact" still erases state.

More fundamentally: Sonnet's change does not address Jim's correction. GPT with minimal tools has done serious work in Zoe. Asking GPT to "run a script in a terminal" is asking GPT to do something it cannot do. The prompt is kind, but it still fails. The design still collapses to First Contact for offline models or stateless chat AIs.

---

## Revised Problem Statement (Post-Jim-Correction)

The problem is not that non-Claude AIs are less capable versions of Zoe. Jim's experience proves they are not. The problem is that Zoe has a sync protocol that assumes file access, and no AI except Claude Code in a terminal has file access. This means the sync protocol effectively does not exist for the majority of Zoe's supported environments. A user who moves from Claude Code to Grok is not downgrading to a lesser Zoe; they are moving to a fully capable Zoe that has no way to inherit state. This is not because Grok is weaker. It is because:

1. ZOE.md never tells Grok what artifact to ask for (the sync block is never named in the user-facing instruction).
2. ZOE.md never tells the user how to generate that artifact (the script exists but is invisible).
3. The one mechanism that does exist (`new_session.sh`) is not integrated into the sync instruction.

This is a *wiring failure*. A working script exists. An undefined format exists. A five-line sync spec exists. They are just not connected to each other, and they are not visible to the user. The fix is not to rebuild the infrastructure. The fix is to *wire it together and make it visible*.

---

## Recommendation: Implement Sonnet's Core Insight, But Rebuild the Wiring

**Do not build Design 1, Design 2, or Design 3.** They are all too ambitious or too pessimistic. Sonnet's recommendation is closer to right, but incomplete.

**Instead: fix the wiring with three minimal changes to ZOE.md:**

### Change 1: Name the artifact in the user-facing sync instruction

Replace this (current):
```
"If you cannot read the repo directly (e.g., Grok, ChatGPT, Gemini in chat):
ask this immediately... 'Do you have a sync block from your last session?'"
```

With this:
```
"If you cannot read the repo directly:
ask immediately: 'Do you have a sync block from your last session? It's a file your
Zoe-in-Claude-Code generates and that you copy when switching AIs. If you have it, paste it here.
If not, can you open a terminal right now and run bash SCRIPTS/new_session.sh? The output is your sync block.'"
```

This names the artifact for the user. "Sync block" becomes a concrete thing they can look for.

### Change 2: Add an explicit write-back instruction in CLAUDE.md

Add this to the Session-End Nudge section:
```
"If you're likely wrapping up and might continue in a different AI:
say this once, naturally: 'Before you close: if you might continue in Grok or another chat tool,
run bash SCRIPTS/new_session.sh and save or copy the output. You'll paste it at the start of
that conversation so that Zoe knows where we left off.'"
```

This makes Claude Code the place where the sync block is *created*, not the place where the user is reminded to run the script at session end.

### Change 3: Formalize the sync block schema in ZOE.md

Add a new section called "Sync Block Format" that says:

```
## Sync Block Format

A Sync Block is a file that captures your state at a moment in time. It starts with:
<!-- zoe-sync-v1 | tier:A | generated:YYYY-MM-DDTHH:MM:SSZ -->

It contains sections marked by ### headings:
- ### Environment
- ### Recent Changelog
- ### Active TODOs
- ### Recent Mailbox

Each AI parses these the same way: extract each section by heading, treat as authoritative state, do not summarize.

When you paste a Sync Block, you're giving me a snapshot. I will orient against it exactly as written.
```

This removes ambiguity about what a sync block *is* and how it should be parsed.

### Why this works

1. **It fixes the wiring without inventing new infrastructure.** `new_session.sh` exists. The format exists. ZOE.md just needs to connect them.
2. **It respects Jim's correction.** It does not declare any AI as "lesser." It treats the same constraints (read-only, no file access) as a protocol problem, not a capability problem.
3. **It is proportionate to the actual gap.** The gap is visibility and naming, not architecture.
4. **It still fails gracefully.** If the user arrives at Grok with no sync block, they fall back to First Contact. Same as today. But if they have one, Zoe uses it. Same as if they had terminal access.
5. **It works for all AIs.** Even offline models, even mobile chat, even air-gapped systems. The protocol is: have artifact → paste it. No URL fetching, no scripting, no terminal dependency.
6. **It does not require new habits.** Claude Code users already commit and close tabs. One nudge at session end. That's it. The sync block appears because they're already using git.

---

## What Should Happen Next

1. **Implement the three wiring changes to ZOE.md.** Make the artifact visible, make the creation moment explicit, make the schema unambiguous.
2. **Do not implement Design 1, 2, or 3.** They are over-engineered for what is actually a wiring problem.
3. **Verify the wiring works.** Have a non-Claude-Code AI (Grok, ChatGPT) attempt a sync-up using only the new ZOE.md instruction. Does it work? If the user has a sync block, does it orient correctly?
4. **Document the fallback path explicitly.** "If you have nothing to paste, run First Contact. This resets context, but it's honest about the gap."

---

## Sonnet Critic's Recommendation, Amended

Sonnet said: "Build Design 1 with one change — invert the prompt."

**Better:** Do not build Design 1 at all. Implement the three wiring changes above. They are Sonnet's insight (invert the prompt, make the message appear when needed) applied to the actual problem (wiring failure), not to the designed solutions (new infrastructure).

The sync protocol does not need to be rebuilt. It needs to be connected. The script exists. The format exists. ZOE.md just needs to tell both Zoe and the user where they are.

---

*Jim's correction cuts through all the design debates: the system works. The user just doesn't know how to use it. Show them.*
