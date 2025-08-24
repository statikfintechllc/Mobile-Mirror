#!/usr/bin/env bash
# Statik-Server Remove Script
# Completely uninstall Statik-Server

set -e

REPO_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
STATIK_HOME="$HOME/.statik-server"

# Colors
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

echo -e "${RED}🗑️  REMOVING STATIK-SERVER${NC}"
echo ""
warn "This will completely remove Statik-Server and all data!"
echo -n "Type 'REMOVE' to confirm: "
read -r CONFIRM

if [[ "$CONFIRM" != "REMOVE" ]]; then
    echo "Removal cancelled"
    exit 0
fi

# Stop any running processes
./stop 2>/dev/null || true

# Remove statik directory
if [[ -d "$STATIK_HOME" ]]; then
    rm -rf "$STATIK_HOME"
    log "Removed $STATIK_HOME"
fi

# Remove desktop app if installed
if [[ -f "$HOME/.local/share/applications/Statik-Server.desktop" ]]; then
    rm -f "$HOME/.local/share/applications/Statik-Server.desktop"
    rm -f "$HOME/.local/share/applications/statik_cli.sh"
    rm -f "$HOME/.local/share/icons/statik-server.png"
    rm -f "$HOME/.local/bin/statik-server"
    rm -f "$HOME/.local/bin/statik-cli"
    log "Removed desktop integration"
fi

# Remove repository (optional)
echo ""
echo -n "Also remove repository directory ($REPO_DIR)? [y/N]: "
read -r REMOVE_REPO

if [[ "$REMOVE_REPO" =~ ^[Yy]$ ]]; then
    cd /
    rm -rf "$REPO_DIR"
    log "Removed repository directory"
    echo ""
    error "Repository removed. This script will now exit."
fi

log "Statik-Server removed completely"
echo ""
echo "To reinstall: git clone <repo-url> && cd statik-server && ./install"
