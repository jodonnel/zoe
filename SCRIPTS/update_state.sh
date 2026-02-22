#!/bin/bash
# update_state.sh — snapshot your environment into STATE/ENVIRONMENT.md
# Run this after major changes to your machine or stack.

set -euo pipefail
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$REPO_DIR/STATE/ENVIRONMENT.md"
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > "$OUT" << EOF
# Environment Snapshot
Last verified: $TS

## OS / Kernel
$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME || echo "unknown")
Kernel: $(uname -r)

## Hardware
CPU: $(grep "Model name" /proc/cpuinfo 2>/dev/null | head -1 | cut -d: -f2 | xargs || echo "unknown")
RAM: $(free -h 2>/dev/null | awk '/Mem:/{print $2}' || echo "unknown")

## Languages / Runtimes
Python: $(python3 --version 2>/dev/null || echo "not found")
Node: $(node --version 2>/dev/null || echo "not found")

## Key Tools
Git: $(git --version 2>/dev/null || echo "not found")
Podman: $(podman --version 2>/dev/null || echo "not found")
Docker: $(docker --version 2>/dev/null || echo "not found")
Claude Code: $(claude --version 2>/dev/null || echo "not found")

## Notes
- This file is GENERATED. Edit SCRIPTS/update_state.sh to change content.
EOF

echo "STATE/ENVIRONMENT.md updated at $TS"
