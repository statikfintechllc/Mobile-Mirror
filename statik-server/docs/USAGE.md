# Statik-Server Usage Guide

## Starting the Server

### Command Line
```bash
# Quick start
statik

# Via CLI
statik-cli start

# Interactive GUI
statik-cli gui
```

### Desktop Application
Click the "Statik Server" icon in your applications menu.

## Accessing the Development Environment

### Web VS Code
- **Local**: http://localhost:8080
- **Network**: http://[your-ip]:8080  
- **Secure**: https://[hostname].statik.local:8443
- **Mobile**: Scan QR code (displayed on startup)

### Local VS Code
```bash
# Interactive workspace selection
statik-cli code

# Open specific project
statik-cli code ~/my-project

# Open current directory
statik-cli code .
```

## CLI Commands

### Core Commands
```bash
statik-cli start          # Start server
statik-cli stop           # Stop server
statik-cli restart        # Restart server
statik-cli status         # Show status
statik-cli logs           # View logs
```

### Development Tools
```bash
statik-cli code           # Open VS Code locally
statik-cli code ~/project # Open specific project
statik-cli open           # Open web VS Code in browser
statik-cli build          # Build/update server
```

### Management
```bash
statik-cli config         # Manage configuration
statik-cli mesh           # Mesh VPN commands
statik-cli gui            # Interactive GUI
statik-cli install       # Install desktop app
```

### Git Integration
```bash
statik-cli commit -m "msg" # Git commit
statik-cli push            # Git push
statik-cli sync -m "msg"   # Add, commit, push
```

## GitHub Copilot

GitHub Copilot works in both web and local VS Code:

### Setup
1. Set GitHub token: `statik-cli config token`
2. Open VS Code (web or local)
3. Sign in to GitHub when prompted
4. Start coding with AI assistance!

### Features
- Code completion and suggestions
- Copilot Chat for questions
- Code explanation and documentation
- Refactoring assistance

## Mesh VPN

Connect other devices to your development mesh:

```bash
# Generate preauth key
statik-cli mesh key

# Connect device
tailscale up --login-server https://[your-domain]:8443 --authkey [key]
```

## Troubleshooting

- Logs: `statik-cli logs`
- Restart: `statik-cli restart`
- Status: `statik-cli status`
- Reset: `rm -rf ~/.statik-server && ./install.sh`
