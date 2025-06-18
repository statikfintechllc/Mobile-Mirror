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

mkdir -p "$APPDIR" "$ICNDIR"

# Copy scripts and launcher *flat* to applications (NOT recursive, NOT keeping folders)
cat > "$APPDIR/mobile_cli.sh" <<EOF
#!/usr/bin/env zsh
set -e

# Guarantee login+interactive shell for environment
if [[ -z "$LOGIN_SHELL_STARTED" ]]; then
    export LOGIN_SHELL_STARTED=1
    exec "$SHELL" -l -i "$0" "$@"
    exit 1
fi

APP_TITLE="Mobile Developer v.1.0.1"
SUB_TITLE="SFTi"

# Resolve script dir
APPDIR="$HOME/.local/share/applications"
ICNDIR="$HOME/.local/share/icons"
START_SCRIPT="$APPDIR/start_code.sh"
STOP_SCRIPT="$APPDIR/stop_code.sh"
LOG_FILE="$HOME/code-server.log"
REMOVE_SCRIPT="$APPDIR/remove_mobile.sh"
    
# Detect preferred shell (get user's shell from /etc/passwd or $SHELL)
USER_SHELL="$(getent passwd "$USER" | cut -d: -f7 2>/dev/null || echo "${SHELL:-/bin/bash}")"

# List of popular emulators
EMULATORS=(x-terminal-emulator gnome-terminal konsole xfce4-terminal lxterminal tilix mate-terminal)

function relaunch_in_terminal() {
    for TERM_APP in "${EMULATORS[@]}"; do
        if command -v "$TERM_APP" &>/dev/null; then
            # Prefer interactive+login if possible
            if [[ "$USER_SHELL" =~ (bash|zsh) ]]; then
                exec "$TERM_APP" -- "$USER_SHELL" -ilc "$0"
            else
                exec "$TERM_APP" -- "$USER_SHELL" -ic "$0"
            fi
            exit 0
        fi
    done
    echo "[ERROR] No graphical terminal emulator found. Exiting."
    exit 1
}

# Check if we're in a terminal, if not relaunch in a graphical one
if ! [ -t 0 ]; then
    relaunch_in_terminal
fi

while true; do
    clear
    UPTIME=$(uptime -p | sed 's/^up //')
    echo -e "\033[1;36m$APP_TITLE\033[0m"
    echo -e "\033[0;32m$SUB_TITLE\033[0m"
    echo -e "Up-Time: \033[1;33m$UPTIME\033[0m"
    echo ""
    echo "Choose an action:"
    echo "1) Start Mobile Tunnel"
    echo "2) Stop Mobile Tunnel"
    echo "3) View Logs"
    echo "4) Exit"
    echo "5) Uninstall Mobile Developer"
    echo -n "Select> "
    read -r CHOICE

    case $CHOICE in
        1)
            bash -l "$START_SCRIPT"
            echo -e "\nMobile Tunnel Started! Press enter to continue..."
            read -r
            ;;
        2)
            bash -l "$STOP_SCRIPT"
            echo -e "\nMobile Tunnel Stopped. Press enter to continue..."
            read -r
            ;;
        3)
            echo -e "\n\033[0;36m[Last 40 lines from: $LOG_FILE]\033[0m"
            tail -n 40 "$LOG_FILE" 2>/dev/null || echo "No log file found at $LOG_FILE"
            echo -e "\nPress enter to continue..."
            read -r
            ;;
        4)
            exit 0
            ;;
        5)
            echo -e "\n\033[1;31mWARNING: This will uninstall Mobile Developer permanently.\033[0m"
            echo -n "Type 'UNINSTALL' to confirm: "
            read -r CONFIRM
            if [[ "$CONFIRM" == "UNINSTALL" ]]; then
                bash -l "$REMOVE_SCRIPT"
                exit 0
            else
                echo "Uninstall cancelled. Press enter to return to menu."
                read -r
            fi
            ;;
        *)
            echo "Invalid choice. Press enter to try again..."
            read -r
            ;;
    esac
done
EOF
sudo chmod +x "$APPDIR/mobile_cli.sh"

cp "$REPO/scripts/start_code.sh" "$APPDIR/start_code.sh"
sudo chmod +x "$APPDIR/start_code.sh"

cp "$REPO/scripts/stop_code.sh" "$APPDIR/stop_code.sh"
sudo chmod +x "$APPDIR/stop_code.sh"

cp "$REPO/scripts/remove_mobile.sh" "$APPDIR/remove_mobile.sh"
sudo chmod +x "$APPDIR/remove_mobile.sh"

cp "$REPO/logs/code-server.log" "$APPDIR/code-server.log"
sudo chmod +x "$APPDIR/code-server.log"

# Copy icon (flat, no folder)
cp "$REPO/env/MobileDeveloper.png" "$ICNDIR/MobileDeveloper.png"
sudo chmod +x "$ICNDIR/MobileDeveloper.png"

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
