#!/usr/bin/env bash
# start-statik-system.sh - Complete Mobile-Mirror + Statik-Server startup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 Starting Complete Statik Mobile Development System"
echo "===================================================="

# Check if install was run
if [[ ! -d "$HOME/.local/share/applications/backend" ]]; then
    echo "❌ Mobile-Mirror not installed. Run: ./env/install.sh"
    exit 1
fi

# Start statik-server with mesh VPN
echo "[1/3] Starting Statik-Server with Mesh VPN..."
if [[ -d "$REPO_ROOT/statik-server" ]]; then
    cd "$REPO_ROOT/statik-server"
    
    # Build if needed
    if [[ ! -f "./out/vs/code/node/cli.js" ]] && [[ ! -f "./lib/statik-server" ]]; then
        echo "[*] Building statik-server..."
        if [[ -f "./build.sh" ]]; then
            ./build.sh
        fi
    fi
    
    # Start in background
    echo "[*] Launching statik-server with mesh VPN..."
    nohup ./startup.sh > ../.statik/logs/statik-server.log 2>&1 &
    
    cd "$SCRIPT_DIR"
    sleep 5
else
    echo "[!] Statik-server directory not found, skipping"
fi

# Start Mobile-Mirror backend
echo "[2/3] Starting Mobile-Mirror backend..."
cd "$HOME/.local/share/applications/backend"
export PATH="$HOME/miniconda/bin:$PATH"
eval "$(conda shell.bash hook)"
conda activate Mob-Dev
nohup python app.py > ../system/services/mobile-mirror-backend.log 2>&1 &

# Start Mobile-Mirror frontend
echo "[3/3] Starting Mobile-Mirror frontend..."
cd "$HOME/.local/share/applications/frontend/public"
nohup npx serve -s . -l 5000 > ../../system/services/mobile-mirror-frontend.log 2>&1 &

sleep 3

echo ""
echo "✅ Complete Statik Development System is running!"
echo ""
echo "📊 Services Status:"
echo "=================="

# Check statik-server
if pgrep -f "statik-server\|cli\.js.*8080" > /dev/null; then
    echo "✅ Statik-Server: Running on http://0.0.0.0:8080"
else
    echo "❌ Statik-Server: Not running"
fi

# Check headscale
if pgrep -f "headscale.*serve" > /dev/null; then
    echo "✅ Mesh VPN: Running on http://127.0.0.1:8080"
    
    # Display preauth key for mobile clients
    if [[ -f "$REPO_ROOT/statik-server/.statik/keys/codetoken" ]]; then
        echo "🔑 Mobile Preauth Key: $(cat "$REPO_ROOT/statik-server/.statik/keys/codetoken")"
    fi
else
    echo "❌ Mesh VPN: Not running"
fi

# Check mobile-mirror backend
if pgrep -f "python.*app\.py" > /dev/null; then
    echo "✅ Mobile-Mirror Backend: Running on http://localhost:8000"
else
    echo "❌ Mobile-Mirror Backend: Not running"
fi

# Check mobile-mirror frontend
if pgrep -f "serve.*5000" > /dev/null; then
    echo "✅ Mobile-Mirror Frontend: Running on http://localhost:5000"
else
    echo "❌ Mobile-Mirror Frontend: Not running"
fi

echo ""
echo "📱 Mobile Access Instructions:"
echo "============================="
echo "1. Install Tailscale/Headscale client on your mobile device"
echo "2. Use the preauth key above to connect to the mesh"
echo "3. Access VS Code: http://[mesh-ip]:8080"
echo "4. Access Mobile-Mirror: http://[mesh-ip]:5000"
echo ""
echo "🔧 Management Commands:"
echo "======================"
echo "Stop all: pkill -f 'statik-server|headscale|app\.py|serve.*5000'"
echo "View logs: tail -f .statik/logs/*.log"
