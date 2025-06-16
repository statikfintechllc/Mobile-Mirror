#!/usr/bin/env bash
# scripts/mobile_dev_cli.sh - Mobile Developer TUI launcher

set -e

while true; do
    CHOICE=$(whiptail --title "Mobile Developer Control Panel" \
        --menu "Choose an action:" 15 60 4 \
        "1" "Start Mobile Tunnel" \
        "2" "Stop Mobile Tunnel" \
        "3" "View Logs" \
        "4" "Exit" 3>&1 1>&2 2>&3)
    
    case $CHOICE in
        1)
            bash "$(dirname "$0")/start_all.sh"
            whiptail --msgbox "Mobile Tunnel Started!" 8 40
            ;;
        2)
            bash "$(dirname "$0")/stop_all.sh"
            whiptail --msgbox "Mobile Tunnel Stopped." 8 40
            ;;
        3)
            LOG=~/code-server.log
            tail -n 40 "$LOG" | whiptail --title "Log Output" --msgbox --scrolltext 30 90
            ;;
        4)
            exit 0
            ;;
    esac
done
