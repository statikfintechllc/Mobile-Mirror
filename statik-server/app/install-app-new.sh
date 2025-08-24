#!/usr/bin/env bash
# Statik-Server App Installer
# Creates a GUI launcher and web interface with global access

set -e

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m'

STATIK_HOME="$HOME/.statik-server"
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
APPDIR="$HOME/.local/share/applications"
ICNDIR="$HOME/.local/share/icons"
BINDIR="$HOME/.local/bin"

# Create web interface for mobile/desktop with tabbed navigation
create_web_interface() {
    local web_dir="$STATIK_HOME/web"
    mkdir -p "$web_dir"
    
    cat > "$web_dir/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🚀 Statik Server - Global AI Development</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white; min-height: 100vh;
        }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .header { text-align: center; margin-bottom: 30px; }
        .header h1 { font-size: 2.5em; margin-bottom: 10px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); }
        .tabs { display: flex; justify-content: center; margin-bottom: 20px; flex-wrap: wrap; }
        .tab { 
            background: rgba(255,255,255,0.15); border: none; color: white; 
            padding: 12px 24px; margin: 3px; border-radius: 20px; cursor: pointer; 
            font-size: 14px; transition: all 0.3s; backdrop-filter: blur(10px);
        }
        .tab:hover, .tab.active { background: rgba(255,255,255,0.25); transform: translateY(-2px); }
        .content { 
            background: rgba(255,255,255,0.1); border-radius: 15px; 
            padding: 25px; backdrop-filter: blur(10px); border: 1px solid rgba(255,255,255,0.1);
        }
        .quick-links { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 15px; }
        .link-card { 
            background: rgba(255,255,255,0.1); padding: 20px; border-radius: 10px; 
            text-align: center; text-decoration: none; color: white; transition: all 0.3s;
            border: 1px solid rgba(255,255,255,0.1);
        }
        .link-card:hover { background: rgba(255,255,255,0.2); transform: translateY(-3px); }
        .link-card h3 { margin-bottom: 8px; font-size: 1.3em; }
        .status { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; }
        .status-item { background: rgba(255,255,255,0.1); padding: 15px; border-radius: 8px; }
        .iframe-container { 
            position: relative; width: 100%; height: 75vh; 
            border-radius: 10px; overflow: hidden; background: rgba(0,0,0,0.2);
        }
        .iframe-container iframe { width: 100%; height: 100%; border: none; }
        @media (max-width: 768px) {
            .header h1 { font-size: 2em; }
            .tabs { flex-direction: column; align-items: center; }
            .tab { width: 90%; text-align: center; margin: 2px 0; }
            .iframe-container { height: 70vh; }
        }
        .btn { 
            background: linear-gradient(45deg, #667eea, #764ba2); color: white; 
            border: none; padding: 8px 16px; margin: 2px; border-radius: 5px; 
            cursor: pointer; transition: all 0.3s;
        }
        .btn:hover { transform: translateY(-1px); box-shadow: 0 4px 8px rgba(0,0,0,0.2); }
        .btn.success { background: linear-gradient(45deg, #4CAF50, #45a049); }
        .btn.danger { background: linear-gradient(45deg, #f44336, #da190b); }
        .btn.warning { background: linear-gradient(45deg, #ff9800, #f57c00); }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Statik Server</h1>
            <p>🌍 Global AI Development Environment • Powered by Tailscale Mesh</p>
        </div>

        <div class="tabs">
            <button class="tab active" onclick="showTab('dashboard')">📊 Dashboard</button>
            <button class="tab" onclick="showTab('vscode')">💻 VS Code</button>
            <button class="tab" onclick="showTab('files')">📁 Files</button>
            <button class="tab" onclick="showTab('status')">⚡ Status</button>
            <button class="tab" onclick="showTab('control')">🎛️ Control</button>
        </div>

        <div id="dashboard" class="content">
            <h2>🌍 Your Global Development Environment</h2>
            <div class="quick-links">
                <a href="#" onclick="showTab('vscode')" class="link-card">
                    <h3>💻 VS Code</h3>
                    <p>Full IDE with Copilot AI</p>
                </a>
                <a href="#" onclick="showTab('files')" class="link-card">
                    <h3>📁 Source Code</h3>
                    <p>Browse /src directory</p>
                </a>
                <a href="#" onclick="showTab('status')" class="link-card">
                    <h3>⚡ System Status</h3>
                    <p>Monitor services</p>
                </a>
                <a href="https://tailscale.com/admin" target="_blank" class="link-card">
                    <h3>🌐 Mesh Network</h3>
                    <p>Tailscale Admin</p>
                </a>
            </div>
        </div>

        <div id="vscode" class="content" style="display:none;">
            <h2>💻 VS Code Web Interface</h2>
            <p style="margin-bottom: 15px;">Full VS Code experience with your source code and GitHub Copilot</p>
            <div class="iframe-container">
                <iframe src="http://localhost:8080" title="VS Code" loading="lazy"></iframe>
            </div>
        </div>

        <div id="files" class="content" style="display:none;">
            <h2>📁 Source Code Browser</h2>
            <p style="margin-bottom: 15px;">Browse and manage your project files</p>
            <div class="iframe-container">
                <iframe src="http://localhost:8080/?folder=/src" title="File Browser" loading="lazy"></iframe>
            </div>
        </div>

        <div id="status" class="content" style="display:none;">
            <h2>⚡ System Status</h2>
            <div class="status">
                <div class="status-item">
                    <h3>🖥️ VS Code Server</h3>
                    <p id="vscode-status">🔄 Checking...</p>
                </div>
                <div class="status-item">
                    <h3>🌐 Tailscale Mesh</h3>
                    <p id="mesh-status">🔄 Checking...</p>
                </div>
                <div class="status-item">
                    <h3>🔒 HTTPS Proxy</h3>
                    <p id="https-status">🔄 Checking...</p>
                </div>
                <div class="status-item">
                    <h3>🤖 GitHub Copilot</h3>
                    <p id="copilot-status">🔄 Checking...</p>
                </div>
            </div>
        </div>

        <div id="control" class="content" style="display:none;">
            <h2>🎛️ Server Control Panel</h2>
            <div class="status">
                <div class="status-item">
                    <h3>🔧 Server Actions</h3>
                    <button onclick="serverAction('start')" class="btn success">▶️ Start Server</button>
                    <button onclick="serverAction('stop')" class="btn danger">⏹️ Stop Server</button>
                    <button onclick="serverAction('restart')" class="btn warning">🔄 Restart</button>
                </div>
                <div class="status-item">
                    <h3>🌐 Access URLs</h3>
                    <p><strong>Local:</strong> <a href="http://localhost:8080" target="_blank" style="color: #87CEEB;">localhost:8080</a></p>
                    <p><strong>HTTPS:</strong> <a href="https://localhost:8443" target="_blank" style="color: #87CEEB;">localhost:8443</a></p>
                    <p><strong>Global:</strong> <span id="tailscale-url">🔄 Checking...</span></p>
                </div>
            </div>
        </div>
    </div>

    <script>
        function showTab(tabName) {
            document.querySelectorAll('.content').forEach(c => c.style.display = 'none');
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            document.getElementById(tabName).style.display = 'block';
            event.target.classList.add('active');
        }

        function serverAction(action) {
            const btn = event.target;
            const originalText = btn.innerHTML;
            btn.innerHTML = '⏳ Processing...';
            btn.disabled = true;
            
            fetch(`/api/${action}`, { method: 'POST' })
                .then(response => response.json())
                .then(data => {
                    alert(`✅ ${action.charAt(0).toUpperCase() + action.slice(1)} successful: ${data.message}`);
                    updateStatus();
                })
                .catch(error => {
                    alert(`❌ Error: ${error.message}`);
                })
                .finally(() => {
                    btn.innerHTML = originalText;
                    btn.disabled = false;
                });
        }

        function updateStatus() {
            // Check VS Code
            fetch('http://localhost:8080', { mode: 'no-cors' })
                .then(() => {
                    document.getElementById('vscode-status').innerHTML = '✅ Running on port 8080';
                })
                .catch(() => {
                    document.getElementById('vscode-status').innerHTML = '❌ Not responding';
                });

            // Check other services (would need API endpoint)
            // For now, show placeholder status
            document.getElementById('mesh-status').innerHTML = '🔄 Detecting Tailscale...';
            document.getElementById('https-status').innerHTML = '🔄 Checking HTTPS proxy...';
            document.getElementById('copilot-status').innerHTML = '🔄 Verifying Copilot...';
            document.getElementById('tailscale-url').innerHTML = '🔄 Getting mesh URL...';
        }

        // Initialize
        document.addEventListener('DOMContentLoaded', updateStatus);
        setInterval(updateStatus, 30000); // Update every 30 seconds
    </script>
</body>
</html>
EOF

    echo -e "${GREEN}✅ Web interface created at $web_dir/index.html${NC}"
}

# Create enhanced GUI launcher
create_gui_launcher() {
    mkdir -p "$BINDIR"
    
    cat > "$BINDIR/statik-gui" << 'EOF'
#!/usr/bin/env bash
# Statik Server GUI Launcher

STATIK_HOME="$HOME/.statik-server"

# Check if zenity is available for GUI
if command -v zenity >/dev/null 2>&1; then
    choice=$(zenity --list --title="🚀 Statik Server" \
        --text="Choose your action:" \
        --width=400 --height=350 \
        --column="🎯 Action" \
        "🚀 Start Server" \
        "⏹️ Stop Server" \
        "💻 Open VS Code" \
        "🌐 Open Web Interface" \
        "📊 Check Status" \
        "📋 View Logs" \
        "🔧 Settings")
    
    case "$choice" in
        "🚀 Start Server")
            zenity --info --width=300 --text="🚀 Starting Statik Server...\n\nThis will launch:\n• VS Code Web Server\n• HTTPS Proxy\n• Tailscale Integration" &
            gnome-terminal -- bash -c "cd $HOME/statik-server && ./scripts/run.sh; read -p 'Press Enter to close...'"
            ;;
        "⏹️ Stop Server")
            if statik-cli stop 2>/dev/null; then
                zenity --info --width=300 --text="✅ Server stopped successfully"
            else
                zenity --error --width=300 --text="❌ Failed to stop server"
            fi
            ;;
        "💻 Open VS Code")
            if command -v xdg-open >/dev/null 2>&1; then
                xdg-open "http://localhost:8080"
            else
                zenity --info --width=300 --text="📋 VS Code URL:\nhttp://localhost:8080"
            fi
            ;;
        "🌐 Open Web Interface")
            if command -v xdg-open >/dev/null 2>&1; then
                xdg-open "https://localhost:8443"
            else
                zenity --info --width=300 --text="📋 Web Interface URL:\nhttps://localhost:8443"
            fi
            ;;
        "📊 Check Status")
            status=$(statik-cli status 2>/dev/null || echo "❌ Server not running or statik-cli not found")
            zenity --info --width=400 --height=200 --text="📊 Status:\n\n$status"
            ;;
        "📋 View Logs")
            if [[ -f "$STATIK_HOME/logs/statik-server.log" ]]; then
                zenity --text-info --width=600 --height=400 --filename="$STATIK_HOME/logs/statik-server.log"
            else
                zenity --info --text="📋 No logs found at:\n$STATIK_HOME/logs/statik-server.log"
            fi
            ;;
        "🔧 Settings")
            zenity --info --width=400 --text="🔧 Settings:\n\n📁 Config: ~/.statik-server/\n🔑 Keys: ~/.statik-server/keys/\n📋 Logs: ~/.statik-server/logs/\n\n🌐 Tailscale: tailscale status"
            ;;
    esac
else
    # Terminal fallback
    echo "🚀 Statik Server Control Panel"
    echo "================================"
    echo "1. 🚀 Start Server"
    echo "2. ⏹️ Stop Server"  
    echo "3. 💻 Open VS Code (localhost:8080)"
    echo "4. 🌐 Open Web Interface (localhost:8443)"
    echo "5. 📊 Check Status"
    echo "6. 📋 View Logs"
    echo "7. 🚪 Exit"
    echo ""
    read -p "Choose option (1-7): " choice
    
    case "$choice" in
        1) cd "$HOME/statik-server" && ./scripts/run.sh ;;
        2) statik-cli stop ;;
        3) xdg-open "http://localhost:8080" 2>/dev/null || echo "Open: http://localhost:8080" ;;
        4) xdg-open "https://localhost:8443" 2>/dev/null || echo "Open: https://localhost:8443" ;;
        5) statik-cli status ;;
        6) tail -f "$STATIK_HOME/logs/statik-server.log" ;;
        7) exit 0 ;;
        *) echo "❌ Invalid option" ;;
    esac
fi
EOF

    chmod +x "$BINDIR/statik-gui"
    echo -e "${GREEN}✅ GUI launcher created at $BINDIR/statik-gui${NC}"
}

# Create desktop app entry
create_desktop_app() {
    mkdir -p "$APPDIR" "$ICNDIR"
    
    # Copy icons if they exist
    if [[ -f "$SCRIPT_DIR/icons/AscendAI-v1.0.3.png" ]]; then
        cp "$SCRIPT_DIR/icons/AscendAI-v1.0.3.png" "$ICNDIR/statik-server.png"
        ICON_PATH="$ICNDIR/statik-server.png"
    else
        ICON_PATH="applications-development"
    fi
    
    # Create desktop entry
    cat > "$APPDIR/statik-server.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Statik Server
Comment=🚀 Global AI Development Environment
Exec=$BINDIR/statik-gui
Icon=$ICON_PATH
Terminal=false
Categories=Development;IDE;Network;
Keywords=vscode;ai;copilot;tailscale;development;mesh;
StartupNotify=true
StartupWMClass=statik-server
MimeType=text/plain;
EOF

    echo -e "${GREEN}✅ Desktop app created${NC}"
}

# Main installation
main() {
    echo -e "${CYAN}🎨 Installing Statik Server App Interface...${NC}"
    
    create_web_interface
    create_gui_launcher  
    create_desktop_app
    
    echo -e "\n${GREEN}🎉 App installation complete!${NC}"
    echo -e "\n${CYAN}🚀 How to use:${NC}"
    echo -e "  ${YELLOW}Desktop:${NC} Search for 'Statik Server' in apps"
    echo -e "  ${YELLOW}Terminal:${NC} Run 'statik-gui'"
    echo -e "  ${YELLOW}Web:${NC} https://localhost:8443 (after starting server)"
    echo -e "  ${YELLOW}VS Code:${NC} http://localhost:8080 (after starting server)"
    echo -e "\n${BLUE}💡 The web interface works perfectly on mobile devices!${NC}"
}

main "$@"
