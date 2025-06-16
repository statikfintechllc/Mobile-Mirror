##!/usr/bin/env bash
set -e

APP_TITLE="Mobile Developer v.1.0.1"
SUB_TITLE="SFTi"

# Resolve current script dir
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
START_SCRIPT="$SCRIPT_DIR/start_code.sh"
STOP_SCRIPT="$SCRIPT_DIR/stop_code.sh"
LOG_FILE="$LOG_FILE/code-server.log"

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
            tail -n 40 "$LOG_FILE" || echo "No log file found at $LOG_FILE"
            echo -e "\nPress enter to continue..."
            read -r
            ;;
        4)
            exit 0
            ;;
        *)
            echo "Invalid choice. Press enter to try again..."
            read -r
            ;;
    esac
done

