#!/usr/bin/env bash
# start_mirror.sh – Launch Mobile Mirror services (backend + frontend)

set -e

# Activate conda environment
export PATH="$HOME/miniconda/bin:$PATH"
eval "$(conda shell.bash hook)"
conda activate Mob-Dev

APPDIR="$HOME/.local/share/applications"
LOGDIR="$APPDIR/system/services"

echo "[*] Starting Mobile Mirror backend..."
cd "$APPDIR/backend"
nohup python3 app.py > "$LOGDIR/touchcore_backend.log" 2>&1 &

echo "[*] Starting Mobile Mirror frontend..."
cd "$APPDIR/frontend/public"
nohup npx serve -s . -l 5000 > "$LOGDIR/touchcore_frontend.log" 2>&1 &

TAIL_IP=$(tailscale ip --4 | head -n1)
echo "[✓] Mobile Mirror Live at: https://$TAIL_IP:5000"
