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
sudo apt install -y tailscale qrencode openssl lsof whiptail

# ---- 2. Install code-server ----

echo "[*] Installing code-server (if not present)..."
if ! command -v code-server >/dev/null 2>&1; then
    curl -fsSL https://code-server.dev/install.sh | sh
else
    echo "[*] code-server already installed."
fi

# ---- 3. Install python requirements (inside conda env) ----

REQS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/requirements.txt"
if [[ -s "$REQS_PATH" ]]; then
    echo "[*] Installing python requirements from $REQS_PATH..."
    pip install --upgrade pip
    pip install -r "$REQS_PATH"
else
    echo "[*] No python requirements found at $REQS_PATH."
fi

# ---- 4. Install the Desktop Launcher (.desktop) ----

echo "[*] Installing Mobile Developer desktop launcher..."

# Source (in repo) and destination (system user applications dir)
DESKTOP_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/MobileDeveloper.desktop"
APPDIR="$HOME/.local/share/applications"
DESKTOP_DEST="$APPDIR/MobileDeveloper.desktop"

mkdir -p "$APPDIR"
cp "$DESKTOP_SRC" "$DESKTOP_DEST"
chmod +x "$DESKTOP_DEST"

echo "[*] Desktop launcher installed at $DESKTOP_DEST"
echo "    - Search for 'Mobile Developer' in your app launcher/menu."
echo "[*] All dependencies installed and app ready to run."
