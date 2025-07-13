#!/usr/bin/env bash
# stop-statik-system.sh - Stop all Statik Mobile Development System services

set -euo pipefail

echo "🛑 Stopping Complete Statik Mobile Development System"
echo "===================================================="

echo "[*] Stopping Mobile-Mirror services..."
pkill -f "python.*app\.py" 2>/dev/null || true
pkill -f "serve.*5000" 2>/dev/null || true

echo "[*] Stopping Statik-Server..."
pkill -f "statik-server" 2>/dev/null || true
pkill -f "cli\.js.*8080" 2>/dev/null || true

echo "[*] Stopping Mesh VPN..."
pkill -f "headscale.*serve" 2>/dev/null || true

echo "✅ All services stopped!"

# Show any remaining processes
REMAINING=$(pgrep -f "statik-server|headscale|app\.py|serve.*5000" 2>/dev/null || true)
if [[ -n "$REMAINING" ]]; then
    echo ""
    echo "⚠️  Some processes may still be running:"
    ps aux | grep -E "statik-server|headscale|app\.py|serve.*5000" | grep -v grep || true
    echo ""
    echo "To force kill: sudo pkill -9 -f 'statik-server|headscale|app\.py|serve'"
fi
