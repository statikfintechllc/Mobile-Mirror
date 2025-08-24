#!/usr/bin/env bash
# Statik-Server Unified Startup Script
# Builds and launches frontend + VS Code with Tailscale tunneling and QR code generation
# Usage: ./startall.sh

set -e

# Colors for output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
PURPLE='\033[1;35m'
NC='\033[0m' # No Color

# Configuration
STATIK_HOME="$HOME/.statik-server"
FRONTEND_PORT=3000
VSCODE_PORT=8080
GREMLINGPT_PORT=8081
TAILSCALE_FRONTEND_NAME="statik-frontend"
TAILSCALE_VSCODE_NAME="statik-vscode"
TAILSCALE_GREMLINGPT_NAME="statik-gremlingpt"
PID_FILE="$STATIK_HOME/startall.pid"
LOG_DIR="$STATIK_HOME/logs"
FRONTEND_LOG="$LOG_DIR/frontend.log"
VSCODE_LOG="$LOG_DIR/vscode-stock.log"
GREMLINGPT_LOG="$LOG_DIR/statik-code.log"
TAILSCALE_LOG="$LOG_DIR/tailscale.log"

# Create necessary directories
mkdir -p "$STATIK_HOME" "$LOG_DIR"

# Logging function
log() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_DIR/startall.log"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_DIR/startall.log"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_DIR/startall.log"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_DIR/startall.log"
}

# Print header
print_header() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║                  🚀 STATIK-SERVER UNIFIED LAUNCHER                 ║"
    echo "║                                                                    ║"
    echo "║   Frontend + VS Code + Tailscale Tunneling + QR Code Generation    ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check for dependencies
check_dependencies() {
    log "Checking dependencies..."

    # Required commands
    local required_commands=("node" "npm" "git" "curl")
    local missing_commands=()

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done

    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        error "Missing required commands: ${missing_commands[*]}"
    fi

    # Check for Tailscale
    if ! command -v tailscale >/dev/null 2>&1; then
        warn "Tailscale not found. Installing Tailscale..."
        install_tailscale
    fi

    # Check for qrencode for QR generation
    if ! command -v qrencode >/dev/null 2>&1; then
        warn "qrencode not found. Installing..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y qrencode
        elif command -v brew >/dev/null 2>&1; then
            brew install qrencode
        else
            warn "Cannot install qrencode automatically. QR codes will not be generated."
        fi
    fi

    success "Dependencies check completed"
}

# Install Tailscale
install_tailscale() {
    log "Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
    success "Tailscale installed"
}

# Check and setup Tailscale authentication
setup_tailscale_auth() {
    log "Setting up Tailscale authentication..."

    # Check if already authenticated
    if tailscale status >/dev/null 2>&1; then
        local tailscale_ip
        tailscale_ip=$(tailscale ip -4 2>/dev/null | head -n1)
        if [[ -n "$tailscale_ip" ]]; then
            log "Already connected to Tailscale: $tailscale_ip"
            echo "$tailscale_ip" > "$STATIK_HOME/tailscale_ip"
            return 0
        fi
    fi

    # Check for auth key in environment
    if [[ -n "$TAILSCALE_AUTHKEY" ]]; then
        log "Using provided auth key..."
        tailscale up --authkey="$TAILSCALE_AUTHKEY" --accept-routes --accept-dns=false
    else
        # Interactive login
        log "Starting Tailscale interactive login..."
        echo -e "${YELLOW}Please complete Tailscale authentication in your browser${NC}"
        tailscale up --accept-routes --accept-dns=false
    fi

    # Get and store IP
    local tailscale_ip
    tailscale_ip=$(tailscale ip -4 2>/dev/null | head -n1)
    if [[ -n "$tailscale_ip" ]]; then
        echo "$tailscale_ip" > "$STATIK_HOME/tailscale_ip"
        success "Tailscale connected: $tailscale_ip"
    else
        error "Failed to get Tailscale IP address"
    fi
}

# Build frontend
build_frontend() {
    log "Building frontend..."

    # Install dependencies
    if [[ -f "package.json" ]]; then
        log "Installing frontend dependencies..."
        if command -v pnpm >/dev/null 2>&1; then
            pnpm install
        else
            npm install
        fi
    fi

    # Build frontend assets
    if [[ -f "ci/build/build-packages.sh" ]]; then
        log "Building frontend packages..."
        ./ci/build/build-packages.sh
    fi

    success "Frontend build completed"
}

# Download and setup VS Code servers
setup_vscode_servers() {
    log "Setting up VS Code servers..."
    
    local lib_dir="./lib"
    mkdir -p "$lib_dir"
    
    # Download code-server if not present
    if [[ ! -f "$lib_dir/code-server" ]]; then
        log "Downloading code-server..."
        local code_server_version="4.92.2"
        local platform="linux"
        local arch="amd64"
        local download_url="https://github.com/coder/code-server/releases/download/v${code_server_version}/code-server-${code_server_version}-${platform}-${arch}.tar.gz"
        
        curl -fsSL "$download_url" -o "/tmp/code-server.tar.gz"
        tar -xzf "/tmp/code-server.tar.gz" -C "/tmp"
        cp "/tmp/code-server-${code_server_version}-${platform}-${arch}/bin/code-server" "$lib_dir/code-server"
        chmod +x "$lib_dir/code-server"
        rm -rf "/tmp/code-server.tar.gz" "/tmp/code-server-${code_server_version}-${platform}-${arch}"
        success "Code-server downloaded and ready"
    fi
    
    # Setup stock VS Code symbolic link
    if [[ ! -f "$lib_dir/vscode-stock" ]]; then
        ln -s "$lib_dir/code-server" "$lib_dir/vscode-stock"
        log "Stock VS Code link created"
    fi
    
    # Setup GremlinGPT VS Code (statik-code)
    if [[ ! -f "$lib_dir/statik-code" ]]; then
        # Create wrapper script for GremlinGPT-enhanced VS Code
        cat > "$lib_dir/statik-code" << 'STATIK_CODE_EOF'
#!/bin/bash
# GremlinGPT-enhanced VS Code launcher
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export VSCODE_EXTENSIONS_DIR="$HOME/.statik-server/extensions/gremlingpt"
export STATIK_GREMLINGPT_MODE=true
export STATIK_GREMLINGPT_CONFIG="$HOME/.statik-server/config/gremlingpt.json"

# Ensure GremlinGPT extensions directory exists
mkdir -p "$VSCODE_EXTENSIONS_DIR"

# Launch code-server with GremlinGPT configuration
exec "$SCRIPT_DIR/code-server" \
    --extensions-dir="$VSCODE_EXTENSIONS_DIR" \
    --user-data-dir="$HOME/.statik-server/vscode-gremlin" \
    "$@"
STATIK_CODE_EOF
        chmod +x "$lib_dir/statik-code"
        success "GremlinGPT VS Code (statik-code) created"
    fi
    
    # Create GremlinGPT configuration
    mkdir -p "$STATIK_HOME/config"
    cat > "$STATIK_HOME/config/gremlingpt.json" << 'GREMLIN_CONFIG_EOF'
{
    "gremlingpt": {
        "enabled": true,
        "ai_model": "local",
        "frontend_integration": true,
        "dashboard_url": "http://localhost:3000",
        "memory_graph": true,
        "autonomous_mode": false
    },
    "extensions": {
        "auto_install": ["ms-python.python", "ms-vscode.cpptools"],
        "gremlin_extensions": ["gremlingpt-core", "gremlingpt-chat"]
    }
}
GREMLIN_CONFIG_EOF
    
    success "VS Code servers setup completed"
}

# Start frontend server
start_frontend() {
    log "Starting frontend server on port $FRONTEND_PORT..."

    # Kill any existing frontend process
    if [[ -f "$STATIK_HOME/frontend.pid" ]]; then
        local old_pid
        old_pid=$(cat "$STATIK_HOME/frontend.pid")
        if kill -0 "$old_pid" 2>/dev/null; then
            kill "$old_pid"
            sleep 2
        fi
    fi

    # Start frontend server
    nohup node out/node/entry.js \
        --bind-addr="0.0.0.0:$FRONTEND_PORT" \
        --disable-telemetry \
        --disable-update-check \
        > "$FRONTEND_LOG" 2>&1 &

    local frontend_pid=$!
    echo "$frontend_pid" > "$STATIK_HOME/frontend.pid"

    # Wait for frontend to start
    sleep 3
    if kill -0 "$frontend_pid" 2>/dev/null; then
        success "Frontend server started (PID: $frontend_pid)"
    else
        error "Failed to start frontend server"
    fi
}

# Start stock VS Code server
start_stock_vscode() {
    log "Starting Stock VS Code server on port $VSCODE_PORT..."
    
    # Kill any existing stock VS Code process
    if [[ -f "$STATIK_HOME/vscode-stock.pid" ]]; then
        local old_pid
        old_pid=$(cat "$STATIK_HOME/vscode-stock.pid")
        if kill -0 "$old_pid" 2>/dev/null; then
            kill "$old_pid"
            sleep 2
        fi
    fi
    
    # Start stock VS Code server
    nohup ./lib/vscode-stock \
        --bind-addr="0.0.0.0:$VSCODE_PORT" \
        --auth=none \
        --disable-telemetry \
        --disable-update-check \
        --disable-workspace-trust \
        > "$LOG_DIR/vscode-stock.log" 2>&1 &
    
    local vscode_pid=$!
    echo "$vscode_pid" > "$STATIK_HOME/vscode-stock.pid"
    
    # Wait for VS Code to start
    sleep 5
    if kill -0 "$vscode_pid" 2>/dev/null; then
        success "Stock VS Code server started (PID: $vscode_pid)"
    else
        error "Failed to start Stock VS Code server"
    fi
}

# Start GremlinGPT VS Code server (statik-code)
start_gremlingpt_vscode() {
    log "Starting GremlinGPT VS Code (statik-code) server on port $GREMLINGPT_PORT..."
    
    # Kill any existing GremlinGPT VS Code process
    if [[ -f "$STATIK_HOME/statik-code.pid" ]]; then
        local old_pid
        old_pid=$(cat "$STATIK_HOME/statik-code.pid")
        if kill -0 "$old_pid" 2>/dev/null; then
            kill "$old_pid"
            sleep 2
        fi
    fi
    
    # Start GremlinGPT VS Code server
    nohup ./lib/statik-code \
        --bind-addr="0.0.0.0:$GREMLINGPT_PORT" \
        --auth=none \
        --disable-telemetry \
        --disable-update-check \
        --disable-workspace-trust \
        > "$LOG_DIR/statik-code.log" 2>&1 &
    
    local gremlin_pid=$!
    echo "$gremlin_pid" > "$STATIK_HOME/statik-code.pid"
    
    # Wait for GremlinGPT VS Code to start
    sleep 5
    if kill -0 "$gremlin_pid" 2>/dev/null; then
        success "GremlinGPT VS Code (statik-code) server started (PID: $gremlin_pid)"
    else
        error "Failed to start GremlinGPT VS Code server"
    fi
}

# Setup Tailscale tunnels
setup_tailscale_tunnels() {
    log "Setting up Tailscale tunnels..."
    
    local tailscale_ip
    tailscale_ip=$(cat "$STATIK_HOME/tailscale_ip" 2>/dev/null)
    
    if [[ -z "$tailscale_ip" ]]; then
        error "Tailscale IP not found. Please ensure Tailscale is connected."
    fi
    
    # Create tunnel configurations
    cat > "$STATIK_HOME/frontend-tunnel.json" << EOF
{
    "name": "$TAILSCALE_FRONTEND_NAME",
    "type": "frontend",
    "local_port": $FRONTEND_PORT,
    "tailscale_ip": "$tailscale_ip",
    "url": "http://$tailscale_ip:$FRONTEND_PORT",
    "https_url": "https://$tailscale_ip:$FRONTEND_PORT",
    "created": "$(date -Iseconds)"
}
EOF
    
    cat > "$STATIK_HOME/vscode-stock-tunnel.json" << EOF
{
    "name": "$TAILSCALE_VSCODE_NAME",
    "type": "vscode-stock",
    "local_port": $VSCODE_PORT,
    "tailscale_ip": "$tailscale_ip",
    "url": "http://$tailscale_ip:$VSCODE_PORT",
    "https_url": "https://$tailscale_ip:$VSCODE_PORT",
    "created": "$(date -Iseconds)"
}
EOF

    cat > "$STATIK_HOME/statik-code-tunnel.json" << EOF
{
    "name": "$TAILSCALE_GREMLINGPT_NAME",
    "type": "statik-code",
    "local_port": $GREMLINGPT_PORT,
    "tailscale_ip": "$tailscale_ip",
    "url": "http://$tailscale_ip:$GREMLINGPT_PORT",
    "https_url": "https://$tailscale_ip:$GREMLINGPT_PORT",
    "created": "$(date -Iseconds)"
}
EOF
    
    success "Tailscale tunnels configured"
    log "Frontend URL: http://$tailscale_ip:$FRONTEND_PORT"
    log "Stock VS Code URL: http://$tailscale_ip:$VSCODE_PORT"
    log "GremlinGPT VS Code URL: http://$tailscale_ip:$GREMLINGPT_PORT"
}

# Generate QR codes
generate_qr_codes() {
    log "Generating QR codes..."

    local tailscale_ip
    tailscale_ip=$(cat "$STATIK_HOME/tailscale_ip" 2>/dev/null)

    if [[ -z "$tailscale_ip" ]]; then
        warn "Cannot generate QR codes: Tailscale IP not found"
        return 1
    fi

    local frontend_url="http://$tailscale_ip:$FRONTEND_PORT"
    local vscode_url="http://$tailscale_ip:$VSCODE_PORT"

    if command -v qrencode >/dev/null 2>&1; then
        # Generate QR code for frontend
        qrencode -t ANSI256 -o "$STATIK_HOME/frontend-qr.txt" "$frontend_url"
        qrencode -t PNG -o "$STATIK_HOME/frontend-qr.png" "$frontend_url"

        # Generate QR code for VS Code
        qrencode -t ANSI256 -o "$STATIK_HOME/vscode-qr.txt" "$vscode_url"
        qrencode -t PNG -o "$STATIK_HOME/vscode-qr.png" "$vscode_url"

        success "QR codes generated in $STATIK_HOME/"

        # Display frontend QR code
        echo -e "\n${CYAN}📱 Frontend Access QR Code:${NC}"
        echo -e "${YELLOW}Scan to access the Statik-Server dashboard${NC}"
        cat "$STATIK_HOME/frontend-qr.txt"
        echo -e "\n${BLUE}Frontend URL: $frontend_url${NC}"

    else
        warn "qrencode not available. QR codes not generated."
        log "Frontend URL: $frontend_url"
        log "VS Code URL: $vscode_url"
    fi
}

# Update frontend configuration for VS Code integration
update_frontend_config() {
    log "Updating frontend configuration..."
    
    local tailscale_ip
    tailscale_ip=$(cat "$STATIK_HOME/tailscale_ip" 2>/dev/null)
    
    if [[ -n "$tailscale_ip" ]]; then
        # Create configuration file for frontend
        cat > "$STATIK_HOME/config.json" << EOF
{
    "frontend": {
        "port": $FRONTEND_PORT,
        "url": "http://$tailscale_ip:$FRONTEND_PORT"
    },
    "vscode": {
        "stock": {
            "port": $VSCODE_PORT,
            "url": "http://$tailscale_ip:$VSCODE_PORT",
            "iframe_src": "http://$tailscale_ip:$VSCODE_PORT",
            "name": "Stock VS Code",
            "description": "Standard VS Code Server"
        },
        "gremlingpt": {
            "port": $GREMLINGPT_PORT,
            "url": "http://$tailscale_ip:$GREMLINGPT_PORT",
            "iframe_src": "http://$tailscale_ip:$GREMLINGPT_PORT",
            "name": "GremlinGPT VS Code",
            "description": "AI-Enhanced VS Code with GremlinGPT"
        }
    },
    "tailscale": {
        "ip": "$tailscale_ip",
        "enabled": true
    },
    "tunnels": {
        "frontend": "$TAILSCALE_FRONTEND_NAME",
        "vscode_stock": "$TAILSCALE_VSCODE_NAME",
        "statik_code": "$TAILSCALE_GREMLINGPT_NAME"
    }
}
EOF
        
        success "Frontend configuration updated"
    fi
}

# Display final status
display_status() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════════════════════════════╗"
    echo -e "║                       🎉 STATIK-SERVER READY                       ║"
    echo -e "╚════════════════════════════════════════════════════════════════════╝${NC}\n"

    local tailscale_ip
    tailscale_ip=$(cat "$STATIK_HOME/tailscale_ip" 2>/dev/null)

    echo -e "${GREEN}✅ All services are running and accessible via Tailscale!${NC}\n"    echo -e "${CYAN}🌐 Access URLs:${NC}"
    if [[ -n "$tailscale_ip" ]]; then
        echo -e "  ${YELLOW}📱 Frontend Dashboard:${NC} http://$tailscale_ip:$FRONTEND_PORT"
        echo -e "  ${YELLOW}💻 Stock VS Code:${NC}     http://$tailscale_ip:$VSCODE_PORT"
        echo -e "  ${YELLOW}🤖 GremlinGPT VS Code:${NC} http://$tailscale_ip:$GREMLINGPT_PORT"
        echo -e "  ${YELLOW}🔒 Local Frontend:${NC}    http://localhost:$FRONTEND_PORT"
        echo -e "  ${YELLOW}🔒 Local Stock VSCode:${NC} http://localhost:$VSCODE_PORT"
        echo -e "  ${YELLOW}🔒 Local GremlinGPT:${NC}   http://localhost:$GREMLINGPT_PORT"
    else
        echo -e "  ${YELLOW}🔒 Local Frontend:${NC}    http://localhost:$FRONTEND_PORT"
        echo -e "  ${YELLOW}🔒 Local Stock VSCode:${NC} http://localhost:$VSCODE_PORT"
        echo -e "  ${YELLOW}🔒 Local GremlinGPT:${NC}   http://localhost:$GREMLINGPT_PORT"
    fi
    
    echo -e "\n${CYAN}📱 Mobile Access:${NC}"
    echo -e "  ${GREEN}1. Scan the QR code above with your mobile device${NC}"
    echo -e "  ${GREEN}2. Access the frontend dashboard${NC}"
    echo -e "  ${GREEN}3. Navigate to either VS Code instance:${NC}"
    echo -e "     ${CYAN}• Stock VS Code:${NC} Standard coding environment"
    echo -e "     ${CYAN}• GremlinGPT VS Code:${NC} AI-enhanced coding with GremlinGPT"
    
    echo -e "\n${CYAN}🔧 Process Information:${NC}"
    local frontend_pid vscode_pid gremlin_pid
    frontend_pid=$(cat "$STATIK_HOME/frontend.pid" 2>/dev/null || echo "Not found")
    vscode_pid=$(cat "$STATIK_HOME/vscode-stock.pid" 2>/dev/null || echo "Not found")
    gremlin_pid=$(cat "$STATIK_HOME/statik-code.pid" 2>/dev/null || echo "Not found")
    echo -e "  ${YELLOW}Frontend PID:${NC}     $frontend_pid"
    echo -e "  ${YELLOW}Stock VS Code PID:${NC} $vscode_pid"
    echo -e "  ${YELLOW}GremlinGPT PID:${NC}    $gremlin_pid"
    
    echo -e "\n${CYAN}📋 Logs:${NC}"
    echo -e "  ${YELLOW}Frontend:${NC}     $FRONTEND_LOG"
    echo -e "  ${YELLOW}Stock VS Code:${NC} $VSCODE_LOG"
    echo -e "  ${YELLOW}GremlinGPT:${NC}    $GREMLINGPT_LOG"
    echo -e "  ${YELLOW}Main:${NC}         $LOG_DIR/startall.log"
    
    echo -e "\n${CYAN}🛑 To stop all services:${NC}"
    echo -e "  ${YELLOW}./scripts/stop.sh${NC} or ${YELLOW}kill \$(cat $STATIK_HOME/*.pid)${NC}"

    echo ""
}

# Cleanup function
cleanup() {
    log "Cleaning up..."

    # Kill processes if they exist
    for pid_file in "$STATIK_HOME/frontend.pid" "$STATIK_HOME/vscode-stock.pid" "$STATIK_HOME/statik-code.pid"; do
        if [[ -f "$pid_file" ]]; then
            local pid
            pid=$(cat "$pid_file")
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid" 2>/dev/null || true
            fi
            rm -f "$pid_file"
        fi
    done

    rm -f "$PID_FILE"
}

# Signal handlers
trap cleanup EXIT
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# Main execution
main() {
    print_header

    # Store main PID
    echo $$ > "$PID_FILE"    # Check if already running
    if [[ -f "$STATIK_HOME/frontend.pid" ]] && [[ -f "$STATIK_HOME/vscode-stock.pid" ]] && [[ -f "$STATIK_HOME/statik-code.pid" ]]; then
        local frontend_pid vscode_pid gremlin_pid
        frontend_pid=$(cat "$STATIK_HOME/frontend.pid")
        vscode_pid=$(cat "$STATIK_HOME/vscode-stock.pid")
        gremlin_pid=$(cat "$STATIK_HOME/statik-code.pid")
        
        if kill -0 "$frontend_pid" 2>/dev/null && kill -0 "$vscode_pid" 2>/dev/null && kill -0 "$gremlin_pid" 2>/dev/null; then
            warn "Statik-Server is already running!"
            warn "Frontend PID: $frontend_pid, Stock VS Code PID: $vscode_pid, GremlinGPT VS Code PID: $gremlin_pid"
            echo -e "${YELLOW}Use './scripts/stop.sh' to stop existing services first${NC}"
            exit 1
        fi
    fi

    # Execute setup steps
    check_dependencies
    setup_tailscale_auth
    build_frontend
    setup_vscode_servers
    start_frontend
    start_stock_vscode
    start_gremlingpt_vscode
    setup_tailscale_tunnels
    update_frontend_config
    generate_qr_codes
    display_status

    # Keep script running
    log "Statik-Server is now running. Press Ctrl+C to stop."
    while true; do
        sleep 10        # Health check
        local frontend_pid vscode_pid gremlin_pid
        frontend_pid=$(cat "$STATIK_HOME/frontend.pid" 2>/dev/null || echo "")
        vscode_pid=$(cat "$STATIK_HOME/vscode-stock.pid" 2>/dev/null || echo "")
        gremlin_pid=$(cat "$STATIK_HOME/statik-code.pid" 2>/dev/null || echo "")
        
        if [[ -n "$frontend_pid" ]] && ! kill -0 "$frontend_pid" 2>/dev/null; then
            error "Frontend process died unexpectedly!"
        fi
        
        if [[ -n "$vscode_pid" ]] && ! kill -0 "$vscode_pid" 2>/dev/null; then
            error "Stock VS Code process died unexpectedly!"
        fi
        
        if [[ -n "$gremlin_pid" ]] && ! kill -0 "$gremlin_pid" 2>/dev/null; then
            error "GremlinGPT VS Code process died unexpectedly!"
        fi
    done
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
