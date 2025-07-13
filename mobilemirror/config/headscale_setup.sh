#!/usr/bin/env bash
# headscale_setup.sh — One-time headscale auth flow for statik-server

set -e

echo "[*] Checking for Headscale client..."
if ! command -v headscale >/dev/null 2>&1; then
    echo "[*] Installing Headscale client..."
    curl -fsSL https://github.com/juanfont/headscale/releases/latest/download/headscale_$(uname -s)_$(uname -m).tar.gz | tar -xzf - -C /tmp
    sudo mv /tmp/headscale /usr/local/bin/
    sudo chmod +x /usr/local/bin/headscale
fi

HEADSCALE_URL="${HEADSCALE_URL:-https://headscale.statikfintech.dev}"
NAMESPACE="${HEADSCALE_NAMESPACE:-statikfintech}"

echo "[*] Configuring Headscale client..."
mkdir -p ~/.config/headscale

cat > ~/.config/headscale/config.yaml <<EOF
server_url: $HEADSCALE_URL
tls_insecure_skip_verify: false
timeout: 5s
EOF

echo "[*] Starting Headscale connection..."
# Use pre-shared key or auth key if available
if [ -f ~/.config/headscale/authkey ]; then
    AUTH_KEY=$(cat ~/.config/headscale/authkey)
    headscale connect --authkey "$AUTH_KEY" --namespace "$NAMESPACE"
else
    echo "[!] No auth key found. Please obtain one from your Headscale server:"
    echo "    headscale preauthkeys create --namespace $NAMESPACE --expiration 1h"
    echo "    Save the key to ~/.config/headscale/authkey"
    exit 1
fi

HEADSCALE_IP=$(headscale status --json | jq -r '.TailscaleIPs[0]' 2>/dev/null || echo "100.64.0.1")
echo "[✓] Headscale connected. IP: $HEADSCALE_IP"
echo "[*] Mobile Mirror will be available at: https://$HEADSCALE_IP:5000"
