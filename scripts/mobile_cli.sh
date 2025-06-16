#!/usr/bin/env bash
set -e

APP_TITLE="Mobile Developer v.1.0.1"
SUB_TITLE="SFTi"

# Ensure terminal emulator context
if ! [ -t 0 ]; then
    for TERM_APP in x-terminal-emulator gnome-terminal konsole xfce4-terminal lxterminal tilix mate-terminal; do
        if command -v "$TERM_APP" &>/dev/null; then
            exec "$TERM_APP" -- bash -ic "$0"
            exit 0
        fi
    done
    echo "[ERROR] No terminal emulator found. Exiting."
    exit 1
fi

# Resolve script dir
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
START_SCRIPT="$SCRIPT_DIR/start_code.sh"
STOP_SCRIPT="$SCRIPT_DIR/stop_code.sh"
LOG_FILE="$SCRIPT_DIR/code-server.log"
REMOVE_SCRIPT="$SCRIPT_DIR/remove_mobile.sh"

# Main loop
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
            bash "$START_SCRIPT"
            echo -e "\nMobile Tunnel Started! Press enter to continue..."
            read -r
            ;;
        2)
            bash "$STOP_SCRIPT"
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
                bash "$REMOVE_SCRIPT"
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

