# SETUP.md — Zoe with Memory

This gives Zoe a private home so she remembers your context across sessions.
Total time: about 5 minutes.

---

## Prerequisites

**Install Git** — version control, required by GitHub CLI
```
https://git-scm.com/downloads
```
Download, install, come back.

**Install GitHub CLI** — lets you create and manage repos from the terminal
```
https://cli.github.com
```
Download, install, come back.

**Create a GitHub account** if you don't have one:
```
https://github.com/join
```

---

## Step 1 — Authenticate with GitHub

This connects your terminal to your GitHub account.
```bash
gh auth login
```
Follow the prompts. Choose GitHub.com → HTTPS → Login with browser.

---

## Step 2 — Create your private Zoe repo

This creates a private repo in your GitHub account and pulls in the Zoe starter files.
```bash
gh repo create YOUR-USERNAME/zoe --private --clone
cd zoe
git remote add template https://github.com/jodonnel/zoe
git fetch template
git merge template/main --allow-unrelated-histories
git remote remove template
git push origin main
```
Replace `YOUR-USERNAME` with your actual GitHub username.

---

## Step 3 — Personalize CLAUDE.md

Open `CLAUDE.md` and fill in:
- `[YOUR NAME]` — your name
- `[YOUR TOP PRIORITY]` — what you're focused on right now
- The **Core Domains** section — your work, projects, what matters

The more specific you are, the more useful Zoe becomes.

---

## Step 4 — First sync

Paste this into your AI (Claude Code, ChatGPT, whatever you use):

```
Sync up. My Zoe repo is at ~/zoe. Read STATE/ENVIRONMENT.md and STATE/CHANGELOG.md,
orient yourself, and tell me what you see.
```

Zoe will read your state and pick up from there.

---

## What you get

| File/Dir | What it does |
|----------|-------------|
| `ZOE.md` | The system prompt — paste into any AI to activate Zoe |
| `CLAUDE.md` | Behavior config for Claude Code specifically — edit this |
| `STATE/CHANGELOG.md` | Log of every change Zoe makes — auto-appended |
| `STATE/MAILBOX.md` | Context notes for future sessions — auto-appended |
| `STATE/ENVIRONMENT.md` | Snapshot of your machine and stack |
| `STATE/TODO.md` | Active work items — keep it to 3-7 |
| `SCRIPTS/update_state.sh` | Regenerates your environment snapshot |

---

## Troubleshooting

**"become Zoe" or roleplay refused**
The AI rejected the system prompt as a roleplay request. Paste the raw gist URL instead of
the text, or preface with: "Use the following as your assistant persona and instructions."

**Clone fails — "repository not found"**
You're not authenticated or used the wrong username. Run `gh auth status` to check. Make
sure the repo name matches exactly what you created.

**GitHub Pages 404 (if you enabled Pages)**
Pages can take 1-2 minutes to build after a push. If it's still 404 after 5 minutes,
check Settings → Pages and confirm the source branch is set to `main`.

**Zoe doesn't remember anything on the next session**
You're probably not in your own repo. Run `git remote -v` — the URL should contain your
GitHub username, not `jodonnel`. If it doesn't, redo Step 2 with your username.

---

*Once setup is done, say "sync up" at the start of every session. That's the whole habit.*
