#!/usr/bin/env bash
# Statik-Server Stop Script
# Stop all running services

set -e

STATIK_HOME="$HOME/.statik-server"

# Colors
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo "🛑 Stopping Statik-Server..."

STOPPED=false

# Stop main process
if [[ -f "$STATIK_HOME/statik.pid" ]]; then
    PID=$(cat "$STATIK_HOME/statik.pid")
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID" 2>/dev/null || kill -9 "$PID" 2>/dev/null
        log "Stopped main process (PID: $PID)"
        STOPPED=true
    fi
    rm -f "$STATIK_HOME/statik.pid"
fi

# Kill any remaining VS Code processes
KILLED_PROCS=$(pkill -f "code serve-web" 2>/dev/null || echo "0")
if [[ "$KILLED_PROCS" != "0" ]]; then
    log "Stopped additional VS Code processes"
    STOPPED=true
fi

if [[ "$STOPPED" == "true" ]]; then
    log "Statik-Server stopped"
else
    warn "No running Statik-Server processes found"
fi
