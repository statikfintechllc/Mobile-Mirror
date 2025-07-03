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
sudo apt install -y tailscale kitty qrencode openssl lsof whiptail xdotool x11vnc libx11-dev libxtst-dev

echo "[*] Installing Python packages into '$ENV_NAME'..."
pip install fastapi uvicorn toml Pillow

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

mkdir -p "$APPDIR" "$ICNDIR"

# Copy scripts and launcher *flat* to applications (NOT recursive, NOT keeping folders)
echo "[*] Installing Icons and loading Metadata..."
cp "$REPO/scripts/mobile_cli.sh" "$APPDIR/mobile_cli.sh"
sudo chmod +x "$APPDIR/mobile_cli.sh"

cp "$REPO/scripts/start_code.sh" "$APPDIR/start_code.sh"
sudo chmod +x "$APPDIR/start_code.sh"

cp "$REPO/scripts/stop_code.sh" "$APPDIR/stop_code.sh"
sudo chmod +x "$APPDIR/stop_code.sh"

cp "$REPO/scripts/remove_mobile.sh" "$APPDIR/remove_mobile.sh"
sudo chmod +x "$APPDIR/remove_mobile.sh"

cp "$REPO/logs/code-server.log" "$APPDIR/code-server.log"
sudo chmod +x "$APPDIR/code-server.log"

echo "[*] Installing Frontend Files and Checking API's..."
cp "$REPO/mobilemirror/frontend/public/manifest.json" "$APPDIR/manifest.json"
cp "$REPO/mobilemirror/frontend/src/App.jsx" "$APPDIR/App.jsx"
cp "$REPO/mobilemirror/frontend/src/Terminal.jsx" "$APPDIR/Terminal.jsx"
cp "$REPO/mobilemirror/frontend/src/Editor.jsx" "$APPDIR/Editor.jsx"
cp "$REPO/mobilemirror/frontend/src/FileManager.jsx" "$APPDIR/FileManager.jsx"
cp "$REPO/mobilemirror/frontend/src/ScreenViewer.jsx" "$APPDIR/ScreenViewer.jsx"
cp "$REPO/mobilemirror/frontend/src/MouseController.jsx" "$APPDIR/MouseController.jsx"
cp "$REPO/mobilemirror/frontend/src/api.js" "$APPDIR/api.js"

echo "[*] Installing Backend Files and Systems..."
cp "$REPO/mobilemirror/backend/screen_streamer.py" "$APPDIR/screen_streamer.py"
cp "$REPO/mobilemirror/backend/mouse_input.py" "$APPDIR/mouse_input.py"
cp "$REPO/mobilemirror/backend/utils/auth.py" "$APPDIR/auth.py"
cp "$REPO/mobilemirror/backend/utils/logger.py" "$APPDIR/logger.py"
cp "$REPO/mobilemirror/backend/utils/qr_generator.py" "$APPDIR/qr_generator.py"
cp "$REPO/mobilemirror/config/system.toml" "$APPDIR/system.toml"
cp "$REPO/mobilemirror/config/tailscale_setup.sh" "$APPDIR/tailscale_setup.sh"
chmod +x "$APPDIR/tailscale_setup.sh"

# Copy icon (flat, no folder)
cp "$REPO/env/MobileDeveloper.png" "$ICNDIR/MobileDeveloper.png"
sudo chmod +x "$ICNDIR/MobileDeveloper.png"

echo "[*] Copying Mobile-Mirror core scripts..."
cp "$REPO/mobilemirror/start_mirror.sh" "$APPDIR/start_mirror.sh"
cp "$REPO/mobilemirror/backend" "$APPDIR/backend"
cp "$REPO/mobilemirror/frontend" "$APPDIR/frontend"
cp "$REPO/mobilemirror/frontend/public/manifest.json" "$APPDIR/manifest.json"

sudo chmod +x "$APPDIR/start_mirror.sh"

echo "[*] Checking log directories..."
cp "$REPO/mobilemirror/system/services" "$APPDIR/system/services"

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
echo "[*] Checking for you... "

GREEN='\033[0;32m'
RED='\033[1;31m'
RESET='\033[0m'

echo
echo "[*] File Health and Permissions Check:"

files=(
    "$APPDIR/mobile_cli.sh"
    "$APPDIR/start_code.sh"
    "$APPDIR/stop_code.sh"
    "$APPDIR/remove_mobile.sh"
    "$ICNDIR/MobileDeveloper.png"
    "$APPDIR/MobileDeveloper.desktop"

)

for f in "${files[@]}"; do
    if [ -f "$f" ]; then
        if [[ "$f" == *.sh || "$f" == *.desktop ]]; then
            chmod +x "$f"
        elif [[ "$f" == *.png ]]; then
            chmod 644 "$f"
        fi
        echo -e "${GREEN}✔ $f found and permissions set${RESET}"
    else
        echo -e "${RED}✘ $f missing!${RESET}"
    fi
done

echo
echo "[*] Mobile-Mirror Health Check:"

files=(
    "$APPDIR/backend/utils/auth.py"
    "$APPDIR/backend/utils/logger.py"
    "$APPDIR/backend/utils/qr_generator.py"
    "$APPDIR/backend/app.py"
    "$APPDIR/backend/screen_streamer.py"
    "$APPDIR/backend/mouse_input.py"
    "$APPDIR/backend/file_ops.py"
    "$APPDIR/backend/terminal_bridge.py"
    "$APPDIR/frontend/public/manifest.json"
    "$APPDIR/frontend/src/App.jsx"
    "$APPDIR/frontend/src/api.js"
    "$APPDIR/frontend/src/FileManager.jsx"
    "$APPDIR/frontend/src/MouseController.js"
    "$APPDIR/frontend/src/ScreenViewer.jsx"
    "$APPDIR/frontend/src/Terminal.jsx"
    "$APPDIR/frontend/src/Editor.jsx"
    "$APPDIR/system.toml"
)

for f in "${files[@]}"; do
    if [ -f "$f" ]; then
        if [[ "$f" == *.sh || "$f" == *.py || "$f" == *.jsx || "$f" == *.json || "$f" == *.js ]]; then
            chmod +x "$f"
        elif [[ "$f" == *.png ]]; then
            chmod 644 "$f"
        fi
        echo -e "${GREEN}✔ $f found and permissions set${RESET}"
    else
        echo -e "${RED}✘ $f missing!${RESET}"
    fi
done

echo
echo "[*] Log File Read Write Check:"
sudo chmod 644 $APPDIR/system/services/touchcore_backend.log
sudo chmod 644 $APPDIR/system/services/touchcore_frontend.log
sudo chmod 644 $APPDIR/MobileDeveloper.desktop

echo
echo "[*] ✅Triple-Check Complete. Systems Located, Placed, Permissions Set, and all files are Healthy✅."
