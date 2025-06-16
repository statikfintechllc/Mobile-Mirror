#!/usr/bin/env bash
# scripts/mobile_dev_cli.sh - Mobile Developer CLI/TUI launcher

set -e

APP_TITLE="Mobile Developer v.1.0.1"
SUB_TITLE="SFTi"

while true; do
    clear
    # Show header info
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
            # Launch start_all.sh (in repo/scripts/)
            bash "$(dirname "$0")/start_all.sh"
            echo -e "\nMobile Tunnel Started! Press enter to continue..."
            read -r
            ;;
        2)
            bash "$(dirname "$0")/stop_all.sh"
            echo -e "\nMobile Tunnel Stopped. Press enter to continue..."
            read -r
            ;;
        3)
            LOG=~/code-server.log
            echo -e "\nLast 40 lines of log:\n"
            tail -n 40 "$LOG"
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
