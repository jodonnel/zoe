#!/bin/bash
# update_state.sh — snapshot environment into STATE/ENVIRONMENT.md
#                   and append a timestamped entry to STATE/CHANGELOG.md
# Run after major changes to your machine, stack, or working context.
# Runs silently on success; prints errors only.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_OUT="$REPO_DIR/STATE/ENVIRONMENT.md"
CHANGELOG="$REPO_DIR/STATE/CHANGELOG.md"
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# --- Resolve identity from git config (repo-local first, then global) ---
GIT_USER=$(git -C "$REPO_DIR" config user.name 2>/dev/null || git config --global user.name 2>/dev/null || echo "unknown")
GIT_EMAIL=$(git -C "$REPO_DIR" config user.email 2>/dev/null || git config --global user.email 2>/dev/null || echo "unknown")

# --- Collect environment facts ---
OS_PRETTY=$(grep -oP 'PRETTY_NAME="\K[^"]+' /etc/os-release 2>/dev/null || uname -s)
KERNEL=$(uname -r)
SHELL_NAME=$(basename "${SHELL:-unknown}")
WORK_DIR=$(pwd)

CPU=$(grep -i "model name" /proc/cpuinfo 2>/dev/null | head -1 | cut -d: -f2 | xargs 2>/dev/null || echo "unknown")
RAM=$(free -h 2>/dev/null | awk '/Mem:/{print $2}' || echo "unknown")

PY_VER=$(python3 --version 2>/dev/null || echo "not found")
NODE_VER=$(node --version 2>/dev/null || echo "not found")

GIT_VER=$(git --version 2>/dev/null || echo "not found")
PODMAN_VER=$(podman --version 2>/dev/null || echo "not found")
DOCKER_VER=$(docker --version 2>/dev/null || echo "not found")
CLAUDE_VER=$(claude --version 2>/dev/null || echo "not found")

# --- Write ENVIRONMENT.md ---
cat > "$ENV_OUT" <<EOF
# Environment Snapshot
Last updated: $TS

## Who I Am
- Git user: $GIT_USER <$GIT_EMAIL>
- Working directory: $WORK_DIR
- Date: $TS

## OS / Kernel
- OS: $OS_PRETTY
- Kernel: $KERNEL
- Shell: $SHELL_NAME

## Hardware
- CPU: $CPU
- RAM: $RAM

## Languages / Runtimes
- Python: $PY_VER
- Node: $NODE_VER

## Key Tools
- Git: $GIT_VER
- Podman: $PODMAN_VER
- Docker: $DOCKER_VER
- Claude Code: $CLAUDE_VER

## Notes
- This file is GENERATED. Edit SCRIPTS/update_state.sh to change what is captured.
- To update: \`bash SCRIPTS/update_state.sh\`
EOF

# --- Append to CHANGELOG.md ---
# Ensure file exists with header if brand new
if [ ! -f "$CHANGELOG" ]; then
    cat > "$CHANGELOG" <<'HEADER'
# Changelog

Format: `- YYYY-MM-DDTHH:MM:SSZ [category]: description`
Categories: `deploy`, `cleanup`, `fix`, `add`, `docs`, `state`, `config`

HEADER
fi

echo "- $TS [state]: environment snapshot updated by $GIT_USER" >> "$CHANGELOG"
