#!/usr/bin/env bash
# stop_remote_dev.sh - Kill code-server on port 8888 and stop Tailscale

set -eu

PORT=8888

echo "[*] Killing all code-server processes on port $PORT..."
PIDS=$(sudo lsof -t -i:$PORT || true)

if [[ -n "$PIDS" ]]; then
    for pid in $PIDS; do
        echo "[*] Killing PID $pid..."
        sudo kill -9 "$pid" || true
    done
    echo "[✓] Killed all code-server processes bound to port $PORT."
else
    echo "[!] No code-server processes found on port $PORT."
fi

echo "[*] Stopping Tailscale daemon..."
sudo systemctl stop tailscaled || true
sudo pkill -9 tailscaled || true
sudo pkill -9 tailscale || true

echo "[*] Cleaning up stale TUN interface (tailscale0)..."
sudo ip link delete tailscale0 2>/dev/null || true

echo "[✓] Remote dev environment fully stopped."

