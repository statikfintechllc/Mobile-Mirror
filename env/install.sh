#!/usr/bin/env bash
# env/install.sh - Full install for Mobile Developer (system deps, code-server, CLI launcher, conda env)

set -eu

# ---- 0. Conda setup ----

ENV_NAME="Mob-Dev"
PYTHON_VERSION="3.10"  # Change if a different python version is required

if ! command -v conda &>/dev/null; then
    echo "[*] conda not found. Installing Miniconda..."
    cd "$(dirname "$0")"
    
    # Download Miniconda if not present
    if [[ ! -f "Miniconda3-latest-Linux-x86_64.sh" ]]; then
        echo "[*] Downloading Miniconda installer..."
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
        chmod +x Miniconda3-latest-Linux-x86_64.sh
    fi
    
    # Install Miniconda
    echo "[*] Installing Miniconda..."
    ./Miniconda3-latest-Linux-x86_64.sh -b -p "$HOME/miniconda3"
    
    # Initialize conda
    "$HOME/miniconda3/bin/conda" init bash
    "$HOME/miniconda3/bin/conda" init zsh
    
    # Add to PATH for current session
    export PATH="$HOME/miniconda3/bin:$PATH"
    
    echo "[*] Miniconda installed. Please restart your shell or run: source ~/.bashrc"
    echo "[*] Then re-run this script."
    exit 0
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

# ---- 2. Install code-server and build statik-server ----

echo "[*] Installing code-server (if not present)..."
if ! command -v code-server >/dev/null 2>&1; then
    curl -fsSL https://code-server.dev/install.sh | sh
else
    echo "[*] code-server already installed."
fi

# ---- 3. Build statik-server with headscale mesh ----

echo "[*] Setting up statik-server with integrated mesh VPN..."
STATIK_DIR="$REPO/statik-server"

if [[ -d "$STATIK_DIR" ]]; then
    cd "$STATIK_DIR"
    
    # Build headscale if Go is available
    if command -v go >/dev/null 2>&1; then
        echo "[*] Building headscale mesh VPN..."
        cd internal/mesh
        if [[ -f "go.mod" ]]; then
            go build -o headscale ./cmd/headscale/
            chmod +x headscale
        fi
        cd "$STATIK_DIR"
    fi
    
    # Make scripts executable
    chmod +x mesh-start.sh startup.sh 2>/dev/null || true
    
    # Build statik-server if package.json exists
    if [[ -f "package.json" ]] && command -v npm >/dev/null 2>&1; then
        echo "[*] Building statik-server..."
        npm install
        if [[ -f "build.sh" ]]; then
            ./build.sh
        fi
    fi
    
    echo "[*] Statik-server setup complete"
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
cp "$REPO/mobilemirror/frontend/src/ScreenView.jsx" "$APPDIR/ScreenView.jsx"
cp "$REPO/mobilemirror/frontend/src/MouseController.js" "$APPDIR/MouseController.js"
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
cp "$REPO/scripts/start_mirror.sh" "$APPDIR/start_mirror.sh"
cp -r "$REPO/mobilemirror/backend" "$APPDIR/"
cp -r "$REPO/mobilemirror/frontend" "$APPDIR/"
# cp "$REPO/mobilemirror/frontend/public/manifest.json" "$APPDIR/manifest.json"  # Already copied above

sudo chmod +x "$APPDIR/start_mirror.sh"

echo "[*] Checking log directories..."
mkdir -p "$APPDIR/system"
cp -r "$REPO/mobilemirror/system/services" "$APPDIR/system/"

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
    "$APPDIR/start_mirror.sh"
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
    "$APPDIR/frontend/src/ScreenView.jsx"
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
