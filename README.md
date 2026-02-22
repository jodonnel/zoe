# Zoe — Your Personal AI Partner

Zoe is a Claude Code setup that gives you a persistent, context-aware AI partner for your work and life.

It's not a product. It's a practice — a way of working with Claude that compounds over time.

## What it is

- A `CLAUDE.md` that defines how Zoe behaves in this directory
- A `STATE/` directory that persists context across sessions
- A `SCRIPTS/` directory for automation
- A simple convention: every change gets logged, every session picks up where the last one left off

## Getting started

### 1. Install Claude Code

```bash
npm install -g @anthropic-ai/claude-code
```

You'll need an Anthropic API key or a Claude Code subscription.

### 2. Clone this repo

```bash
git clone https://github.com/jodonnel/zoe ~/zoe
cd ~/zoe
```

### 3. Personalize CLAUDE.md

Open `CLAUDE.md` and replace the `[YOUR NAME]` and `[YOUR TOP PRIORITY]` placeholders with your actual info. The more specific you are, the more useful Zoe becomes.

### 4. Initialize your state

```bash
bash SCRIPTS/update_state.sh
```

### 5. Start a session

```bash
cd ~/zoe
claude
```

Say: **"sync up"** — Zoe will read your state and pick up where you left off.

## The core habit

At the start of every session: `sync up`
After every meaningful change: Zoe logs it to `STATE/CHANGELOG.md` and `STATE/MAILBOX.md`

That's it. The system builds itself over time.

## Directory structure

```
~/zoe/
├── CLAUDE.md          # How Zoe behaves — edit this first
├── STATE/
│   ├── CHANGELOG.md   # What changed and when
│   ├── MAILBOX.md     # Context for future sessions
│   ├── ENVIRONMENT.md # Your machine/stack snapshot (generated)
│   └── TODO.md        # Active work items
├── SCRIPTS/
│   └── update_state.sh  # Snapshot your environment
└── README.md
```

## Philosophy

- **Boring is good.** Markdown files and shell scripts outlast frameworks.
- **State is yours.** Nothing leaves your machine you didn't put there.
- **Compound interest.** Every logged change makes the next session smarter.

---

Built on [Claude Code](https://claude.ai/claude-code) by Anthropic.
