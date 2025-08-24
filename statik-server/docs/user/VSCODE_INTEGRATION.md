# 💻 VS Code Integration Guide

Statik-Server provides seamless integration with both local desktop VS Code and web-based VS Code environments.

## 🎯 Overview

You can access VS Code in two ways:
- **Local Desktop VS Code**: Native application with full extension support
- **Web VS Code**: Browser-based development environment

Both environments support GitHub Copilot Chat and share the same workspace capabilities.

## 🖥️ Local VS Code (Desktop)

### Quick Start
```bash
# Interactive workspace selection
statik-cli code

# Open specific directory
statik-cli code ~/my-project

# Open current directory
statik-cli code .
```

### Interactive Options
When you run `statik-cli code` without arguments, you'll see:

```
What would you like to open?
1) Current directory (/current/path)
2) Home directory (/home/user)
3) Statik-Server directory (/path/to/statik-server)
4) Custom path
Select (1-4):
```

### GUI Interface
Use the interactive GUI app:
1. Run `statik-cli gui` or `statik-server`
2. Select option **9) Open VS Code Locally**
3. Choose your workspace from the same 4 options

## 🌐 Web VS Code (Browser)

### Access Methods
```bash
# Open in default browser
statik-cli open

# Direct URLs
http://localhost:8080              # Local access
http://[your-ip]:8080             # Network access
https://[hostname].statik.local:8443  # Secure domain
```

### Mobile Access
Scan the QR code displayed during startup to access web VS Code from mobile devices.

## 🤖 GitHub Copilot Integration

Both local and web VS Code environments come pre-configured with GitHub Copilot Chat.

### First-Time Setup
1. Start VS Code (local or web)
2. Sign in to GitHub when prompted
3. Copilot Chat will be automatically enabled

### Features Available
- ✅ Code completion and suggestions
- ✅ Chat-based AI assistance
- ✅ Code explanation and documentation
- ✅ Bug detection and fixes
- ✅ Test generation
- ✅ Refactoring suggestions

## 🔄 Workspace Synchronization

### Settings Sync
Enable VS Code Settings Sync to keep your configuration consistent between local and web environments:

1. In VS Code: `Ctrl+Shift+P` → "Settings Sync: Turn On"
2. Sign in with GitHub
3. Your settings, extensions, and keybindings will sync across all instances

### Extensions
- **Local VS Code**: Install any extension from the marketplace
- **Web VS Code**: Limited to web-compatible extensions
- **Recommendation**: Use Settings Sync to maintain consistency

## 🛠️ Configuration

### GitHub Token Setup
```bash
# Set GitHub token for Copilot access
statik-cli config token
```

### Custom VS Code Settings
Settings are stored in `~/.statik-server/config/vscode-settings.json` and automatically applied.

## 🚨 Troubleshooting

### VS Code Binary Not Found
```bash
# Reinstall VS Code CLI
./install.sh
```

### Copilot Not Working
1. Check GitHub token: `statik-cli config`
2. Sign in to GitHub in VS Code
3. Ensure you have Copilot access on your GitHub account

### Port Conflicts
If port 8080 is in use:
```bash
# Check status
statik-cli status

# Stop and restart
statik-cli restart
```

## 📱 Mobile Development

### Responsive Web Interface
The web VS Code interface is optimized for mobile devices with:
- Touch-friendly interface
- Mobile-optimized keyboard shortcuts
- Responsive layout that adapts to screen size

### QR Code Access
Scan the QR code displayed on startup for instant mobile access to your development environment.

---

## 🔗 Related Documentation

- [CLI Reference](../CLI_REFERENCE.md) - All commands and options
- [Mobile Access Guide](./MOBILE_ACCESS.md) - Mobile development setup
- [Troubleshooting](../TROUBLESHOOTING.md) - Common issues and solutions
