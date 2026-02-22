# Critique: Attacking the Proposals

**Author:** Critic
**Date:** 2026-02-22
**Input:** Scout's gap analysis, Architect's three designs, Jim's correction
**Jim's correction (verbatim):** "The 'works in any AI' is true. It works to the extent that it has integrated capabilities, but even if those are strictly limited, like in GPT, it has been able to build git and apps, same as you."

---

## The Weight of Jim's Correction

Before attacking anything: Jim's correction is load-bearing. It eliminates the cleanest escape hatch all three designs were implicitly using — the assumption that "works in any AI" is aspirational marketing that can be quietly undermined with tier language, capability disclaimers, or honest degradation notices. Jim says no. GPT with no terminal has built git repos and deployed apps. Zoe's promise holds. The problem is not that non-Claude AIs are lesser Zoes. The problem is that the sync protocol doesn't work across any of them, regardless of what they can build.

This changes the attack surface on every proposal.

---

## Design 1 Attack: Paste-First Protocol (The Disciplined Habit)

### What it gets right

Design 1 is the only proposal that treats `new_session.sh` as the asset it already is rather than proposing new infrastructure. The script exists. It produces a useful blob. The gap Scout identified is real and narrow: ZOE.md never mentions the script where users look for sync instructions. Design 1's fix is proportionate — add the reference, define the format, make the parser instructions explicit. The three-rung ladder (read files → paste blob → First Contact) is the right shape for the problem. The write-back artifact (formatted shell heredoc) is clever: it turns a manual step into a single copy-paste action rather than pretending the step doesn't exist.

The schema design (`<!-- zoe-sync-v1 -->` with `###` section markers) is minimal and correct. It can be parsed by any AI without special training. The version marker makes future changes detectable. This is good engineering.

### What it gets wrong

The Architect named the fatal flaw clearly — the habit is the load-bearing structure — but did not follow that admission to its conclusion. A design whose success depends entirely on a user action that happens *before* the session that needs it, with no prompt, no reminder, and no fallback when it fails, is not a design. It is a procedure. Procedures fail. When this one fails (user arrives at Grok with no blob), the spec's ladder collapses immediately to First Contact, erasing all Level 3 state. That is not a graceful degradation. It is the same broken experience that exists today, wrapped in better documentation.

There is also a subtler problem: Design 1 assumes the session-end ritual can be taught through ZOE.md alone. But ZOE.md is read by Zoe, not by the user. The user does not read ZOE.md. Zoe reads it and behaves accordingly. If the session-end write-back prompt only lives in ZOE.md's self-checklist, then the prompt appears when Zoe has already been instantiated in a session — meaning the prompt to "run new_session.sh" arrives at the *end* of a Grok session, when the user is done, not at the *start* of a Grok session when the user needs the state. The timing is inverted.

Design 1 solves the documentation gap. It does not solve the bootstrap gap.

---

## Design 2 Attack: State-as-URL (The Hosted Snapshot)

### What it gets right

Design 2 correctly identifies that the friction point is not "paste a blob" but "know what blob to paste and have it available." A URL solves the availability problem elegantly — the user only needs to remember their GitHub username, which they already know. The JSON schema is unambiguous across all AIs, eliminates markdown parsing variance, and the `apply_writeback.sh` script genuinely reduces write-back from four manual steps to one. The idea of a git hook that auto-publishes state after every commit is the right level of automation — it requires no new user habit, it piggybacks on a workflow that already exists.

For technical users with public repos, Design 2 is the cleanest solution and the right long-term architecture.

### What it gets wrong

The Architect's stated fatal flaw (private repos return 404, GitHub auth is a security surface) is real but it is not the most damaging flaw. The most damaging flaw is that Design 2 introduces new infrastructure — `push_state.sh`, `apply_writeback.sh`, `STATE/sync.json`, a git hook, and a published URL — before the existing infrastructure (`new_session.sh`, `STATE/MAILBOX.md`) is even properly wired into ZOE.md. You cannot build the highway before you've fixed the on-ramp.

Design 2 also has a silent failure mode that Design 1 does not: if `push_state.sh` fails silently (network down, hook not installed, permission error), the URL returns stale state. The user pastes it to Grok. Grok orients against data that is days old. No error. No warning. This is worse than a missing sync blob — at least a missing blob forces First Contact, which is honest about the gap. A stale URL gives Grok false confidence.

Finally, Design 2 solves bootstrap for Tier B (browsing-capable AIs) and does nothing for Tier C (offline models, enterprise-firewalled AIs, mobile chat). Jim's correction means we cannot accept a solution that works for some AIs and not others. The URL mechanism is not universally reachable.

---

## Design 3 Attack: Zoe-Lite Read-Only Mode (The Explicit Downgrade)

This design gets hit hardest because Jim's correction directly invalidates its core assumption.

### What it gets right

Design 3 is the only proposal that explicitly addresses the write-back problem without pretending it can be solved by automation. The deferred write-back model — non-Claude AIs produce a write-back artifact, Claude Code applies it next time — is honest, auditable, and requires no new infrastructure. The instruction to Claude Code ("if you receive a block starting with `<!-- zoe-writeback -->`, apply it before doing anything else") is concrete and implementable with a single addition to CLAUDE.md.

The tier-aware sync instruction is also correct in shape, even if wrong in framing. There is a real difference between what Claude Code can do (read and write files directly) and what Grok can do (produce text for the user to act on). That difference should be acknowledged somewhere, because it affects what Zoe asks the user to do at session start.

### What it gets wrong

Design 3's core assumption is that "works in any AI" is a false promise that should be corrected through transparency. Jim says it is not a false promise. GPT with limited tools has built git repos and deployed apps, same as Claude. The design pattern that follows from this assumption — Tier A is real Zoe, Tier B/C are Zoe Lite — is therefore wrong. It solves the wrong problem.

The tier labeling does something worse than being wrong: it teaches the user to expect less from non-Claude AIs before they have tried anything. A user who reads "Tier C: cannot persist state without a manual step" may conclude that Grok-Zoe is not worth using for serious work. But Jim's experience says Grok-Zoe has done serious work. The tier label creates a ceiling that the actual capability does not have. The problem is not that Grok cannot do the work. The problem is that Grok cannot read STATE/ files — a sync protocol problem, not a capability problem.

There is a second failure specific to Design 3's write-back path: it requires the user to eventually return to Claude Code. If they do not — if they switch to Grok permanently, if their employer blocks Claude, if they simply prefer another tool — the write-back artifact sits in their clipboard or chat history and state diverges permanently. Design 3 calls this a design constraint. Jim's correction reveals it as an architectural assumption about which AI the user will eventually return to — an assumption that "works in any AI" explicitly rejects.

The tier framing is also internally inconsistent with ZOE.md's self-description. ZOE.md says: "You work in ChatGPT, Claude, Grok, Gemini, or anything else. The user picks the best tool. You adapt." Design 3 says: "You are Tier C if you're in Gemini. You are read-only. You cannot persist state." These two statements cannot both be in the same system prompt without contradicting each other. Zoe cannot adapt to any AI and also be explicitly degraded in specific AIs. One of them has to give. Jim's correction says the system prompt wins.

---

## Revised Problem Statement (Post-Jim-Correction)

The problem is not that non-Claude AIs are less capable versions of Zoe — they are not. The problem is that Zoe has a sync protocol that only works when the AI can read files directly, and no AI except Claude Code in a terminal can do that, which means the sync protocol effectively does not exist for the majority of Zoe's supported environments. A user who moves from Claude Code to Grok is not moving to a degraded Zoe; they are moving to a fully capable Zoe that has no way to learn what happened in the last session, not because Grok is weaker but because ZOE.md never tells Grok what to ask for, never tells the user what to provide, and never connects the one existing mechanism (`new_session.sh`) to the sync instruction the user actually triggers. The actual problem is a wiring failure: a working script, an undefined format, and a five-line sync spec that assumes file access without ever acknowledging that most of Zoe's runtime environments do not have it.

---

## Recommendation: Build Design 1 with One Change

**Build Design 1.** It is the only proposal that is proportionate to the actual problem Jim's correction reveals. The problem is a wiring failure, not an architecture failure. Design 1 fixes the wiring. Design 2 builds new infrastructure before the wiring is fixed. Design 3 mislabels the wiring failure as a capability gap.

**The single change that makes Design 1 work:** Invert the session-end prompt into a session-start prompt.

Design 1 as written relies on the user running `new_session.sh` *before* they leave Claude Code, so they have something to paste when they arrive at Grok. This is a habit that requires foresight. Users do not have foresight at session end — they have completed a task and they close the tab.

The fix: Claude Code's CLAUDE.md self-checklist adds one item at session end, generated by Zoe automatically:

> "Before you close this session: if you might continue in a different AI, run `bash SCRIPTS/new_session.sh` and save or copy the output. You'll need it to sync up."

And ZOE.md's sync instruction adds one Zoe behavior at session *start* in any non-file-capable AI:

> "If I cannot read your repo directly, ask: 'Do you have a sync block from your last session? If not, can you open a terminal and run `bash SCRIPTS/new_session.sh`?' If they have neither, run First Contact."

This shifts the prompt from a user habit (run script before leaving) to a Zoe behavior (ask for the artifact at the moment it is needed). The user does not need to remember to run the script. They need to be able to run it when Zoe asks — which they can do in any terminal, even after arriving at Grok, even from their phone via SSH. The habit is replaced with a prompt. Prompts are more reliable than habits.

Everything else in Design 1 — the schema, the version marker, the write-back heredoc — is correct and should be built as specified.

---

*The sync protocol does not need to be rebuilt. It needs to be connected.*
