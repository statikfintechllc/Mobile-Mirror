#!/usr/bin/env bash
# env/install.sh - Full install for Mobile Developer (system deps, code-server, CLI launcher)

set -eu

# ---- 1. Install system dependencies ----

echo "[*] Installing required apt packages..."
sudo apt update
grep -vE '^\s*#|^\s*$' apt.txt | xargs --no-run-if-empty sudo apt install -y

# Always install whiptail (for TUI)
sudo apt install -y whiptail

# ---- 2. Install code-server ----

echo "[*] Installing code-server (if not present)..."
if ! command -v code-server >/dev/null 2>&1; then
    curl -fsSL https://code-server.dev/install.sh | sh
else
    echo "[*] code-server already installed."
fi

# ---- 3. Install python requirements (optional) ----

echo "[*] Installing python requirements (if any)..."
if [[ -s requirements.txt ]]; then
    pip install -r requirements.txt
else
    echo "[*] No python requirements."
fi

# ---- 4. Install the Desktop Launcher (.desktop) ----

echo "[*] Installing Mobile Developer desktop launcher..."

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"
APPDIR="$HOME/.local/share/applications"
ICON_PATH="$APPDIR/MobileDeveloper.desktop"
SCRIPT_PATH="$SCRIPTDIR/mobile_dev_cli.sh"

mkdir -p "$APPDIR"

cat > "$ICON_PATH" <<EOF
[Desktop Entry]
Type=Application
Name=Mobile Developer
Exec=$SCRIPT_PATH
Icon=utilities-terminal
Terminal=true
Categories=Development;Utility;
Comment=Start/Stop Mobile Developer Tunnel and VSCode
EOF

chmod +x "$SCRIPT_PATH"
chmod +x "$ICON_PATH"

echo "[*] App icon created at $ICON_PATH"
echo "    - You can now search for 'Mobile Developer' and pin it to your launcher/dash."

echo "[*] All dependencies installed and app ready to run."
