#!/usr/bin/env bash
# env/install.sh - Full install for Mobile Developer (system deps, code-server, CLI launcher, conda env)

set -eu

# ---- 0. Conda setup ----

ENV_NAME="Mob-Dev"
PYTHON_VERSION="3.10"  # Change if a different python version is required

if ! command -v conda &>/dev/null; then
    echo "[ERROR] conda not found. Please install Miniconda or Anaconda first."
    exit 1
fi

echo "[*] Checking if conda env '$ENV_NAME' exists..."
if conda info --envs | awk '{print $1}' | grep -qx "$ENV_NAME"; then
    echo "[*] Conda env '$ENV_NAME' already exists."
else
    echo "[*] Creating conda env '$ENV_NAME' with Python $PYTHON_VERSION..."
    conda create -y -n "$ENV_NAME" python=$PYTHON_VERSION
fi

echo "[*] Activating conda env '$ENV_NAME'..."
# shellcheck disable=SC1091
eval "$(conda shell.bash hook)"
conda activate "$ENV_NAME"

# ---- 1. Install system dependencies ----

echo "[*] Installing required apt packages..."
sudo apt update
sudo apt install -y tailscale kitty qrencode openssl lsof whiptail

# ---- 2. Install code-server ----

echo "[*] Installing code-server (if not present)..."
if ! command -v code-server >/dev/null 2>&1; then
    curl -fsSL https://code-server.dev/install.sh | sh
else
    echo "[*] code-server already installed."
fi

# Paths
REPO="$(cd "$(dirname "$0")/.." && pwd)"
APPDIR="$HOME/.local/share/applications"
ICNDIR="$HOME/.local/share/icons"
LOG_FILE="$APPDIR/code-server.log"

mkdir -p "$APPDIR" "$ICNDIR" "$LOG_FILE"

# Copy scripts *flat* to applications (NOT recursive, NOT keeping folders)
cp "$REPO/scripts/mobile_cli.sh" "$APPDIR/mobile_cli.sh"
sudo chmod +x "$APPDIR/mobile_cli.sh"

cp "$REPO/scripts/start_code.sh" "$APPDIR/start_code.sh"
sudo chmod +x "$APPDIR/mobile_cli.sh"

cp "$REPO/scripts/stop_code.sh" "$APPDIR/stop_code.sh"
sudo chmod +x "$APPDIR/stop_code.sh"

cp "$REPO/logs/code-server.log" "$LOG_FILE/code-server.log"
sudo chmod +x "$LOG_FILE/code-server.log"

# Copy icon (flat, no folder)
cp "$REPO/env/MobileDeveloper.png" "$ICNDIR/MobileDeveloper.png"

# Write .desktop file with ONLY BARE FILENAMES, no paths
cat > "$APPDIR/MobileDeveloper.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Mobile Developer v.1.0.1
Comment=SFTi
Exec=$APPDIR/mobile_cli.sh
Icon=$ICNDIR/MobileDeveloper.png
Terminal=true
Categories=Development;Utility;
EOF

sudo chmod +x "$APPDIR/MobileDeveloper.desktop"

echo "[*] Mobile Developer installed. Look for 'Mobile Developer' in your launcher menu."
