# Setting Up Zoe

Before anything else, Zoe needs a home of her own.

## Step 1 — Create your own private repo

Do this once. Zoe lives in your GitHub, not someone else's.

```bash
# Install GitHub CLI if you don't have it
# https://cli.github.com

# Authenticate
gh auth login

# Create your private Zoe repo and push
gh repo create YOUR-USERNAME/zoe --private --clone
cd zoe

# Pull the starter content from the template
git remote add template https://github.com/jodonnel/zoe
git fetch template
git merge template/main --allow-unrelated-histories
git remote remove template

# Push to your repo
git push origin main
```

Now you own Zoe. Updates from the template are yours to pull when you want them.

## Step 2 — Personalize

Open `CLAUDE.md` and fill in:
- `[YOUR NAME]` — your name
- `[YOUR TOP PRIORITY]` — what you're working on right now
- The **Core Domains** section — your work, projects, personal priorities

Be specific. The more Zoe knows about your world, the more useful she is.

## Step 3 — Snapshot your environment

```bash
bash SCRIPTS/update_state.sh
git add STATE/ENVIRONMENT.md
git commit -m "state: initial environment snapshot"
git push
```

## Step 4 — Start your first session

```bash
cd ~/zoe
claude
```

Say: **"sync up"**

Zoe will read your state and introduce herself. From here, the system builds itself.

---

## Why your own repo?

- Your state, your history, your secrets stay yours.
- You can invite collaborators, add your own scripts, fork in any direction.
- When Zoe gets smarter, you pull the update on your terms.
