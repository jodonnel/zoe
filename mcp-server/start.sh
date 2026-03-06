#!/bin/bash
# Start Zoe MCP server + Cloudflare Tunnel
# Usage: bash ~/zoe/mcp-server/start.sh
#   stop: bash ~/zoe/mcp-server/start.sh stop

set -euo pipefail

CONTAINER_NAME="zoe-mcp"
PORT=8000

if [ "${1:-}" = "stop" ]; then
    podman rm -f "$CONTAINER_NAME" 2>/dev/null
    pkill -f "cloudflared tunnel" 2>/dev/null
    echo "[zoe-mcp] Stopped."
    exit 0
fi

# Stop any existing
podman rm -f "$CONTAINER_NAME" 2>/dev/null
pkill -f "cloudflared tunnel" 2>/dev/null
sleep 1

# Start MCP server container
echo "[zoe-mcp] Starting container..."
podman run -d --name "$CONTAINER_NAME" \
    -p "${PORT}:${PORT}" \
    -v /home/jodonnell/zoe:/state:Z \
    localhost/zoe-mcp:latest

sleep 2

# Verify it's up
if ! curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:${PORT}/mcp -H "Content-Type: application/json" -d '{}' 2>/dev/null | grep -q "200\|400"; then
    echo "[zoe-mcp] ERROR: Container not responding"
    podman logs "$CONTAINER_NAME"
    exit 1
fi
echo "[zoe-mcp] Container up on port ${PORT}"

# Start Cloudflare Tunnel
echo "[zoe-mcp] Starting Cloudflare Tunnel..."
~/.local/bin/cloudflared tunnel --url http://localhost:${PORT} \
    --no-autoupdate \
    > /tmp/zoe-tunnel.log 2>&1 &

# Wait for tunnel URL
for i in $(seq 1 15); do
    TUNNEL_URL=$(grep -oP 'https://[a-z0-9-]+\.trycloudflare\.com' /tmp/zoe-tunnel.log 2>/dev/null | head -1)
    if [ -n "$TUNNEL_URL" ]; then
        break
    fi
    sleep 1
done

if [ -z "${TUNNEL_URL:-}" ]; then
    echo "[zoe-mcp] WARNING: Tunnel URL not found yet. Check /tmp/zoe-tunnel.log"
    exit 1
fi

echo ""
echo "============================================"
echo " Zoe MCP Server Live"
echo "============================================"
echo " Local:  http://localhost:${PORT}/mcp"
echo " Public: ${TUNNEL_URL}/mcp"
echo ""
echo " Claude Web: Settings > Connectors > Add custom"
echo "   URL: ${TUNNEL_URL}/mcp"
echo ""
echo " Claude Code: add to ~/.claude/settings.json"
echo "   mcpServers.zoe.url = \"http://localhost:${PORT}/mcp\""
echo "============================================"
echo ""
echo " Stop: bash ~/zoe/mcp-server/start.sh stop"
