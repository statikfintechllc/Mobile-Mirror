# Statik Mobile Development System

A complete self-hosted mobile development environment with VS Code (statik-server) and integrated mesh VPN (headscale) for secure mobile access.

## 🚀 Quick Start

### 1. Install the System
```bash
cd Mobile-Mirror/env
./install.sh
```

### 2. Start Everything
```bash
cd Mobile-Mirror/scripts
./start-statik-system.sh
```

### 3. Connect from Mobile
1. Install Tailscale/Headscale client on your mobile device
2. Use the preauth key displayed after startup
3. Access VS Code at `http://[mesh-ip]:8080`
4. Access Mobile-Mirror at `http://[mesh-ip]:5000`

## 📊 System Components

### Core Services
- **Statik-Server**: Self-hosted VS Code with Copilot integration
- **Headscale Mesh VPN**: Private mesh network for secure mobile access
- **Mobile-Mirror Backend**: Python FastAPI service for file operations and terminal access
- **Mobile-Mirror Frontend**: React web interface for mobile control

### Security Features
- No public ports or cloud dependencies
- Encrypted mesh VPN communication
- Persistent preauth keys with rotation support
- File system access controls
- Token-based API authentication

## 🔧 Configuration

### Directory Structure
```
statik-server/
├── .statik/
│   ├── keys/           # Authentication keys (gitignored)
│   ├── config/         # Headscale and system config
│   ├── data/           # Runtime data (gitignored)
│   └── logs/           # System logs (gitignored)
├── internal/mesh/      # Integrated headscale
├── mesh-start.sh       # Mesh VPN startup script
└── startup.sh          # Complete system startup
```

### Key Files
- `.statik/keys/codetoken`: Mobile device preauth key
- `.statik/config/headscale.yaml`: Mesh VPN configuration
- `.statik/config/acl.hujson`: Network access control policy

## 🛠️ Management Commands

### Start/Stop Services
```bash
# Start complete system
./scripts/start-statik-system.sh

# Stop all services
./scripts/stop-statik-system.sh

# Start just mesh VPN
./statik-server/mesh-start.sh

# Start just statik-server
./statik-server/startup.sh
```

### Monitor System
```bash
# View all logs
tail -f .statik/logs/*.log

# Check service status
ps aux | grep -E "statik-server|headscale|app\.py|serve"

# View mesh network status
./statik-server/internal/mesh/headscale --config .statik/config/headscale.yaml nodes list
```

### Manage Mobile Clients
```bash
# Generate new preauth key
./statik-server/internal/mesh/headscale --config .statik/config/headscale.yaml \
  preauthkeys create --namespace statik-mesh --expiration 0s

# List connected devices
./statik-server/internal/mesh/headscale --config .statik/config/headscale.yaml nodes list

# Remove a device
./statik-server/internal/mesh/headscale --config .statik/config/headscale.yaml \
  nodes delete --identifier [node-id]
```

## 🔒 Security Considerations

### Network Security
- Mesh VPN uses WireGuard encryption
- No external dependencies or cloud services
- All communication encrypted end-to-end
- ACL policies control network access

### Key Management
- Preauth keys stored in `.statik/keys/` (gitignored)
- Keys copied to `/root/.statik/keys/` during runtime
- Automatic key generation on first startup
- Keys never expire by default (configurable)

### File System Access
- Full file system access through VS Code
- Mobile-Mirror provides controlled file operations
- Token-based API authentication
- Configurable access controls

## 🐛 Troubleshooting

### Common Issues

**Mesh VPN not starting:**
```bash
# Check if headscale binary exists
ls -la statik-server/internal/mesh/headscale

# Build headscale manually
cd statik-server/internal/mesh
go build -o headscale ./cmd/headscale/
```

**Can't connect from mobile:**
```bash
# Check mesh VPN is running
ps aux | grep headscale

# Verify preauth key
cat .statik/keys/codetoken

# Check network connectivity
curl http://127.0.0.1:8080
```

**Services not starting:**
```bash
# Check conda environment
conda info --envs | grep Mob-Dev

# Verify Python packages
conda activate Mob-Dev && python -c "import fastapi, uvicorn"

# Check Node.js installation
node --version && npm --version
```

### Logs and Debugging
- Statik-Server: `.statik/logs/statik-server.log`
- Mesh VPN: `.statik/logs/headscale.log`
- Mobile-Mirror Backend: `~/.local/share/applications/system/services/mobile-mirror-backend.log`
- Mobile-Mirror Frontend: `~/.local/share/applications/system/services/mobile-mirror-frontend.log`

## 🔧 Advanced Configuration

### Custom Mesh Settings
Edit `.statik/config/headscale.yaml` to customize:
- IP address ranges
- DERP server configuration
- Database settings
- Logging levels

### Statik-Server Options
Modify `statik-server/startup.sh` to adjust:
- Bind address and port
- Extension directories
- User data location
- Authentication settings

### Mobile-Mirror Customization
Configure Mobile-Mirror by editing:
- `mobilemirror/config/system.toml`
- Backend API endpoints
- Frontend interface options

## 📱 Mobile Client Setup

### Android/iOS
1. Install official Tailscale app
2. Configure custom server: `http://[server-ip]:8080`
3. Use preauth key from `.statik/keys/codetoken`
4. Connect and access services via mesh IP

### Custom Clients
- Headscale is compatible with all Tailscale clients
- Can build custom clients using WireGuard libraries
- API available for programmatic access

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Test with complete system startup
4. Submit pull request

## 📄 License

This project integrates multiple open-source components:
- Statik-Server: Based on VS Code (MIT License)
- Headscale: BSD-3-Clause License
- Mobile-Mirror: Custom license (see LICENSE file)
