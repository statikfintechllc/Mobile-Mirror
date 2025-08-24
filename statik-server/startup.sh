#!/usr/bin/env bash
# Startup script for Tailscale tunneling integration
# This script handles the explicit Tailscale tunnel setup for frontend and VS Code

set -e

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m'

# Configuration
STATIK_HOME="$HOME/.statik-server"
FRONTEND_PORT=3000
VSCODE_PORT=8080

# Logging
log() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Start frontend application server
start_frontend_server() {
    log "Starting frontend application server..."

    # Ensure we're in the right directory
    cd "$(dirname "$0")"

    # Check if Node.js is available
    if ! command -v node >/dev/null 2>&1; then
        error "Node.js is required but not installed"
    fi

    # Install dependencies if needed
    if [[ ! -d "node_modules" ]] && [[ -f "package.json" ]]; then
        log "Installing dependencies..."
        npm install
    fi

    # Build if needed
    if [[ ! -d "out" ]]; then
        log "Building application..."
        npm run build 2>/dev/null || {
            log "Building with alternative method..."
            if [[ -f "ci/build/build-packages.sh" ]]; then
                ./ci/build/build-packages.sh
            fi
        }
    fi

    # Start the frontend server
    log "Launching frontend on port $FRONTEND_PORT..."
    export STATIK_FRONTEND_MODE=true
    export STATIK_DEFAULT_PORT=$FRONTEND_PORT

    nohup node out/node/entry.js \
        --bind-addr="0.0.0.0:$FRONTEND_PORT" \
        --disable-telemetry \
        --disable-update-check \
        > "$STATIK_HOME/logs/frontend.log" 2>&1 &

    local frontend_pid=$!
    echo "$frontend_pid" > "$STATIK_HOME/frontend.pid"

    # Wait and verify
    sleep 3
    if kill -0 "$frontend_pid" 2>/dev/null; then
        success "Frontend server started (PID: $frontend_pid)"
        return 0
    else
        error "Failed to start frontend server"
    fi
}

# Start VS Code server
start_vscode_server() {
    log "Starting VS Code server..."

    # Start VS Code on separate port
    log "Launching VS Code on port $VSCODE_PORT..."

    nohup node out/node/entry.js \
        --bind-addr="0.0.0.0:$VSCODE_PORT" \
        --disable-telemetry \
        --disable-update-check \
        --disable-workspace-trust \
        --without-connection-token \
        > "$STATIK_HOME/logs/vscode.log" 2>&1 &

    local vscode_pid=$!
    echo "$vscode_pid" > "$STATIK_HOME/vscode.pid"

    # Wait and verify
    sleep 5
    if kill -0 "$vscode_pid" 2>/dev/null; then
        success "VS Code server started (PID: $vscode_pid)"
        return 0
    else
        error "Failed to start VS Code server"
    fi
}

# Create and activate Tailscale tunnel
create_tailscale_tunnel() {
    log "Creating and activating Tailscale tunnels..."

    # Check if Tailscale is installed
    if ! command -v tailscale >/dev/null 2>&1; then
        warn "Tailscale not found. Installing..."
        curl -fsSL https://tailscale.com/install.sh | sh
    fi

    # Check if already connected
    local tailscale_ip
    tailscale_ip=$(tailscale ip -4 2>/dev/null | head -n1)

    if [[ -z "$tailscale_ip" ]]; then
        log "Connecting to Tailscale..."
        if [[ -n "$TAILSCALE_AUTHKEY" ]]; then
            tailscale up --authkey="$TAILSCALE_AUTHKEY" --accept-routes --accept-dns=false
        else
            log "Starting interactive Tailscale login..."
            echo -e "${YELLOW}Please complete authentication in your browser${NC}"
            tailscale up --accept-routes --accept-dns=false
        fi

        # Get IP after connection
        tailscale_ip=$(tailscale ip -4 2>/dev/null | head -n1)
    fi

    if [[ -n "$tailscale_ip" ]]; then
        echo "$tailscale_ip" > "$STATIK_HOME/tailscale_ip"
        success "Tailscale connected: $tailscale_ip"

        # Document tunnel URLs
        log "Frontend tunnel URL: http://$tailscale_ip:$FRONTEND_PORT"
        log "VS Code tunnel URL: http://$tailscale_ip:$VSCODE_PORT"

        # Save tunnel configuration
        cat > "$STATIK_HOME/tunnel-config.json" << EOF
{
    "tailscale_ip": "$tailscale_ip",
    "frontend": {
        "port": $FRONTEND_PORT,
        "url": "http://$tailscale_ip:$FRONTEND_PORT",
        "tunnel_active": true
    },
    "vscode": {
        "port": $VSCODE_PORT,
        "url": "http://$tailscale_ip:$VSCODE_PORT",
        "tunnel_active": true
    },
    "created": "$(date -Iseconds)"
}
EOF

        return 0
    else
        error "Failed to establish Tailscale connection"
    fi
}

# Generate QR code for frontend access
generate_qr_code() {
    log "Generating QR code for frontend access..."

    local tailscale_ip
    tailscale_ip=$(cat "$STATIK_HOME/tailscale_ip" 2>/dev/null)

    if [[ -z "$tailscale_ip" ]]; then
        warn "Cannot generate QR code: Tailscale IP not available"
        return 1
    fi

    local frontend_url="http://$tailscale_ip:$FRONTEND_PORT"

    # Install qrencode if not available
    if ! command -v qrencode >/dev/null 2>&1; then
        log "Installing qrencode..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y qrencode
        elif command -v brew >/dev/null 2>&1; then
            brew install qrencode
        else
            warn "Cannot install qrencode. QR code generation skipped."
            log "Frontend URL: $frontend_url"
            return 1
        fi
    fi

    # Generate QR code
    qrencode -t ANSI256 -o "$STATIK_HOME/frontend-qr.txt" "$frontend_url"
    qrencode -t PNG -o "$STATIK_HOME/frontend-qr.png" "$frontend_url"

    success "QR code generated!"

    # Display QR code
    echo -e "\n${CYAN}📱 Scan this QR code to access Statik-Server:${NC}"
    echo -e "${BLUE}$frontend_url${NC}\n"
    cat "$STATIK_HOME/frontend-qr.txt"
    echo ""

    return 0
}

# Update frontend configuration with tunnel URLs
update_frontend_tunnel_config() {
    log "Updating frontend configuration for tunnel access..."

    local tailscale_ip
    tailscale_ip=$(cat "$STATIK_HOME/tailscale_ip" 2>/dev/null)

    if [[ -n "$tailscale_ip" ]]; then
        # Create runtime configuration for frontend
        mkdir -p "$STATIK_HOME/config"
        cat > "$STATIK_HOME/config/runtime.json" << EOF
{
    "mode": "production",
    "tunneling": {
        "enabled": true,
        "provider": "tailscale",
        "tailscale_ip": "$tailscale_ip"
    },
    "services": {
        "frontend": {
            "url": "http://$tailscale_ip:$FRONTEND_PORT",
            "port": $FRONTEND_PORT,
            "tunnel_active": true
        },
        "vscode": {
            "url": "http://$tailscale_ip:$VSCODE_PORT",
            "port": $VSCODE_PORT,
            "tunnel_active": true,
            "iframe_src": "http://$tailscale_ip:$VSCODE_PORT"
        }
    },
    "navigation": {
        "default_page": "frontend",
        "vscode_integration": "embedded_iframe"
    }
}
EOF

        success "Frontend tunnel configuration updated"
    fi
}

# Main startup sequence
main() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗"
    echo -e "║                🚀 STATIK-SERVER STARTUP SCRIPT                   ║"
    echo -e "║                                                                  ║"
    echo -e "║  Explicit Tailscale tunneling for Frontend + VS Code services   ║"
    echo -e "╚══════════════════════════════════════════════════════════════════╝${NC}\n"

    # Create required directories
    mkdir -p "$STATIK_HOME/logs" "$STATIK_HOME/config"

    # Execute startup sequence
    log "Initiating Statik-Server startup sequence..."

    start_frontend_server
    start_vscode_server
    create_tailscale_tunnel
    update_frontend_tunnel_config
    generate_qr_code

    # Final status
    echo -e "\n${GREEN}✅ Statik-Server is now running with Tailscale tunneling!${NC}\n"

    local tailscale_ip
    tailscale_ip=$(cat "$STATIK_HOME/tailscale_ip" 2>/dev/null)

    if [[ -n "$tailscale_ip" ]]; then
        echo -e "${CYAN}🌍 Access URLs:${NC}"
        echo -e "  ${YELLOW}Frontend (Default):${NC} http://$tailscale_ip:$FRONTEND_PORT"
        echo -e "  ${YELLOW}VS Code:${NC}            http://$tailscale_ip:$VSCODE_PORT"
        echo -e "\n${CYAN}📱 User Workflow:${NC}"
        echo -e "  ${GREEN}1.${NC} Scan the QR code above"
        echo -e "  ${GREEN}2.${NC} Access the frontend interface"
        echo -e "  ${GREEN}3.${NC} Navigate to VS Code via the '💻 VS Code' tab"
    fi

    echo -e "\n${CYAN}Logs:${NC} $STATIK_HOME/logs/"
    echo -e "${CYAN}Config:${NC} $STATIK_HOME/config/"
    echo ""
}

# Execute main function
main "$@"
