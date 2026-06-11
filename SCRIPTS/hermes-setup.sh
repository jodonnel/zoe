#!/usr/bin/env bash
# hermes-setup.sh — Get Hermes + Zoe running in 5 minutes
# For Red Hat team members. Prompts for API key or guides through MaaS.
set -euo pipefail

echo ""
echo "========================================="
echo "  Hermes + Zoe Setup"
echo "========================================="
echo ""

# 1. Check Python
if ! command -v python3 &>/dev/null; then
    echo "ERROR: python3 not found. Install it first:"
    echo "  sudo dnf install python3 python3-pip"
    exit 1
fi

# 2. Install Hermes
if command -v hermes &>/dev/null; then
    echo "[ok] Hermes already installed: $(hermes --version 2>/dev/null || echo 'unknown')"
else
    echo "[install] Installing Hermes Agent..."
    pip install --user hermes-agent
    export PATH="$HOME/.local/bin:$PATH"
    if command -v hermes &>/dev/null; then
        echo "[ok] Hermes installed."
    else
        echo "ERROR: Hermes install failed. Try: pip install --user hermes-agent"
        exit 1
    fi
fi

# 3. Clone Zoe
if [ -d "$HOME/zoe" ]; then
    echo "[ok] ~/zoe already exists."
else
    echo "[setup] Cloning Zoe..."
    if command -v gh &>/dev/null; then
        read -rp "Your GitHub username: " GH_USER
        gh repo create "$GH_USER/zoe" --private --clone 2>/dev/null || true
        cd "$HOME/zoe"
        git remote add template https://github.com/jodonnel/zoe 2>/dev/null || true
        git fetch template
        git merge template/main --allow-unrelated-histories --no-edit 2>/dev/null || true
        git remote remove template 2>/dev/null || true
        git push origin main 2>/dev/null || true
        cd "$HOME"
        echo "[ok] Zoe repo created at ~/zoe"
    else
        echo "[setup] No GitHub CLI found. Cloning template directly..."
        git clone https://github.com/jodonnel/zoe "$HOME/zoe"
        echo "[ok] Zoe cloned to ~/zoe (no private repo — set one up later with 'gh')"
    fi
fi

# 4. API Key
echo ""
echo "========================================="
echo "  API Configuration"
echo "========================================="
echo ""
echo "Hermes needs a model provider. Options:"
echo ""
echo "  1) xAI (Grok) — free tier available"
echo "     Sign up: https://console.x.ai"
echo ""
echo "  2) Red Hat MaaS — free for Red Hat employees"
echo "     Models: Granite, Qwen3, DeepSeek, Llama Scout"
echo "     Endpoint: https://litellm-prod.apps.maas.redhatworkshops.io/v1"
echo ""
echo "  3) Anthropic — Claude models, paid"
echo "     Sign up: https://console.anthropic.com"
echo ""
echo "  4) I already have a key (paste it)"
echo ""
echo "  5) Skip for now"
echo ""
read -rp "Choose [1-5]: " CHOICE

PROVIDER=""
API_KEY=""
BASE_URL=""
MODEL=""

case "$CHOICE" in
    1)
        PROVIDER="xai"
        BASE_URL="https://api.x.ai/v1"
        MODEL="grok-3"
        echo ""
        echo "Get your key at: https://console.x.ai/team/default/api-keys"
        read -rp "Paste your xAI API key: " API_KEY
        ;;
    2)
        PROVIDER="maas"
        BASE_URL="https://litellm-prod.apps.maas.redhatworkshops.io/v1"
        MODEL="granite-3-2-8b-instruct"
        echo ""
        echo "Red Hat MaaS setup:"
        echo "  1. Go to https://demo.redhat.com"
        echo "  2. Search for 'Model as a Service'"
        echo "  3. Order the environment"
        echo "  4. You'll receive an API key in your confirmation email"
        echo ""
        read -rp "Paste your RHDP MaaS API key: " API_KEY
        ;;
    3)
        PROVIDER="anthropic"
        BASE_URL="https://api.anthropic.com/v1"
        MODEL="claude-sonnet-4-6"
        echo ""
        echo "Get your key at: https://console.anthropic.com/settings/keys"
        read -rp "Paste your Anthropic API key: " API_KEY
        ;;
    4)
        echo ""
        read -rp "Provider name (xai/anthropic/openai/maas): " PROVIDER
        read -rp "API key: " API_KEY
        read -rp "Base URL (or press Enter for default): " BASE_URL
        read -rp "Model name: " MODEL
        case "$PROVIDER" in
            xai) BASE_URL="${BASE_URL:-https://api.x.ai/v1}"; MODEL="${MODEL:-grok-3}" ;;
            anthropic) BASE_URL="${BASE_URL:-https://api.anthropic.com/v1}"; MODEL="${MODEL:-claude-sonnet-4-6}" ;;
            openai) BASE_URL="${BASE_URL:-https://api.openai.com/v1}"; MODEL="${MODEL:-gpt-4o}" ;;
            maas) BASE_URL="${BASE_URL:-https://litellm-prod.apps.maas.redhatworkshops.io/v1}"; MODEL="${MODEL:-granite-3-2-8b-instruct}" ;;
        esac
        ;;
    5)
        echo ""
        echo "Skipping API setup. Run this script again when you have a key."
        echo "Or configure manually: hermes config set providers.<name>.api_key <key>"
        ;;
esac

# 5. Write Hermes config
if [ -n "$API_KEY" ] && [ -n "$PROVIDER" ]; then
    mkdir -p "$HOME/.hermes"

    if [ ! -f "$HOME/.hermes/config.yaml" ]; then
        cat > "$HOME/.hermes/config.yaml" << YAML
model:
  default: $MODEL
  provider: $PROVIDER
  context_length: 1000000
providers:
  $PROVIDER:
    api_key: $API_KEY
    base_url: $BASE_URL
toolsets:
- file
- code_execution
agent:
  max_turns: 90
display:
  compact: false
  bell_on_complete: true
  streaming: false
YAML
        echo "[ok] Hermes configured: provider=$PROVIDER model=$MODEL"
    else
        echo "[exists] ~/.hermes/config.yaml already exists. Adding provider..."
        hermes config set "providers.$PROVIDER.api_key" "$API_KEY" 2>/dev/null || true
        hermes config set "providers.$PROVIDER.base_url" "$BASE_URL" 2>/dev/null || true
        hermes config set model.default "$MODEL" 2>/dev/null || true
        hermes config set model.provider "$PROVIDER" 2>/dev/null || true
        echo "[ok] Provider $PROVIDER configured."
    fi
fi

# 6. Copy Zoe system prompt into Hermes
if [ -f "$HOME/zoe/ZOE.md" ]; then
    mkdir -p "$HOME/.hermes"
    if [ ! -f "$HOME/.hermes/SOUL.md" ]; then
        cp "$HOME/zoe/ZOE.md" "$HOME/.hermes/SOUL.md"
        echo "[ok] Zoe personality loaded into Hermes (SOUL.md)"
    else
        echo "[exists] ~/.hermes/SOUL.md already exists. Not overwriting."
        echo "         To use Zoe's personality: cp ~/zoe/ZOE.md ~/.hermes/SOUL.md"
    fi
fi

# 7. Personalization reminder
echo ""
echo "========================================="
echo "  Almost done"
echo "========================================="
echo ""
echo "Edit ~/zoe/CLAUDE.md with your name and priorities."
echo "This is what Zoe reads to know who you are."
echo ""

# 8. Test
if [ -n "$API_KEY" ] && [ -n "$PROVIDER" ]; then
    echo "Testing connection..."
    if hermes -p "$PROVIDER" -m "$MODEL" --oneshot "Say hello in one sentence." 2>/dev/null; then
        echo ""
        echo "[ok] Connection works."
    else
        echo "[warn] Test failed. Check your API key and try: hermes --oneshot 'hello'"
    fi
fi

echo ""
echo "========================================="
echo "  Ready"
echo "========================================="
echo ""
echo "Start Hermes:"
echo "  cd ~/zoe && hermes"
echo ""
echo "See the kanban board:"
echo "  hermes board"
echo ""
echo "First thing to say:"
echo "  'Sync up. Read STATE/ENVIRONMENT.md and tell me what you see.'"
echo ""
