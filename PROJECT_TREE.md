# 🌳 Mobile Mirror - Complete Project Tree

## 📋 Project Structure Overview

```
.
├── app
│   ├── cli
│   │   └── statik-cli
│   │
│   ├── gui
│   │
│   ├── icons
│   │   └── AscendAI-v1.0.3.png
│   │
│   ├── install-app-fixed.sh
│   └── install-app.sh
│   
├── docs
│   ├── BUILD_COMPLETE.md
│   ├── development
│   │   ├── REORGANIZATION.md
│   │   └── STRUCTURE.md
│   │
│   ├── INSTALL.md
│   │
│   ├── mesh
│   │   └── MESH_OVERVIEW.md
│   │
│   ├── README-CLEAN.md
│   ├── README-old2.md
│   ├── README-old.md
│   ├── README_STATIK.md
│   ├── USAGE.md
│   │
│   └── user
│       └── APP_INTERFACE.md
│   
├── internal
│   │
│   └── mesh
│       ├── buf.gen.yaml
│       ├── CHANGELOG.md
│       ├── cmd
│       ├── CODE_OF_CONDUCT.md
│       ├── config-example.yaml
│       ├── CONTRIBUTING.md
│       ├── derp-example.yaml
│       ├── Dockerfile.derper
│       ├── Dockerfile.integration
│       ├── Dockerfile.tailscale-HEAD
│       ├── docs
│       ├── flake.nix
│       ├── gen
│       ├── go.mod
│       ├── go.sum
│       ├── headscale
│       ├── headscale.sh
│       ├── headscale.yaml
│       ├── hscontrol
│       ├── integration
│       ├── LICENSE
│       ├── Makefile
│       ├── mkdocs.yml
│       ├── packaging
│       ├── proto
│       ├── README.md
│       └── swagger.go
│   
├── lib
│   ├── code
│   ├── vscode
│   └── vscode_cli.tar.gz
│   
├── scripts
│   ├── build.sh
│   ├── domain-setup.sh
│   ├── mesh-start.sh
│   ├── quick-build.sh
│   ├── setup.sh
│   ├── startup-clean.sh
│   ├── startup-new.sh
│   ├── startup-old.sh
│   ├── startup.sh
│   ├── test-setup.sh
│   └── vscode-broadcast.sh
│   
├── src
│   ├── AscendAI-v1.0.3.png
│   │
│   ├── browser
│   │   ├── favicon.afdesign
│   │   ├── media
│   │   ├── pages
│   │   ├── robots.txt
│   │   ├── security-clean.txt
│   │   ├── security-old.txt
│   │   ├── security.txt
│   │   └── serviceWorker.ts
│   │
│   ├── common
│   │   ├── emitter.ts
│   │   ├── http.ts
│   │   └── util.ts
│   │
│   └── node
│       ├── app.ts
│       ├── cli.ts
│       ├── constants.ts
│       ├── entry.ts
│       ├── heart.ts
│       ├── http.ts
│       ├── i18n
│       ├── main.ts
│       ├── proxy.ts
│       ├── routes
│       ├── settings.ts
│       ├── socket.ts
│       ├── statik
│       ├── update.ts
│       ├── util.ts
│       ├── vscodeSocket.ts
│       ├── wrapper.ts
│       └── wsRouter.ts
│   
├── bootstrap.sh
├── Broadcasting
├── config
├── LICENSE
├── install.sh
├── package.json
├── README.md
└── tsconfig.json
```

## 📁 Directory Details

### 📱 mobilemirror/backend/
**Purpose**: Core FastAPI backend providing mobile-desktop integration APIs

**Key Components**:
- `app.py` - Main FastAPI application with comprehensive API endpoints
- `file_ops.py` - Secure file system operations with path validation
- `terminal_bridge.py` - Real-time WebSocket terminal access
- `mouse_input.py` - Cross-platform mouse input simulation
- `screen_streamer.py` - VNC-based desktop streaming with quality control

**Features**:
- RESTful API for file operations
- WebSocket terminal connections
- Mouse input simulation
- Screen streaming management
- Comprehensive error handling
- Security controls and validation

### 🛠️ mobilemirror/backend/utils/
**Purpose**: Shared utility modules providing core functionality

**Key Components**:
- `logger.py` - Centralized logging with structured JSON output
- `auth.py` - Authentication system with rate limiting and security
- `qr_generator.py` - QR code generation for mobile device connection

**Features**:
- Structured logging with rotation
- Token-based authentication
- Rate limiting and IP blocking
- QR code generation with metadata
- Performance monitoring decorators
- Security audit logging

### 🖥️ statik-server/
**Purpose**: VS Code server integration with mesh VPN

**Key Components**:
- `startup.sh` - Complete system initialization
- `mesh-start.sh` - Headscale VPN startup
- `internal/mesh/` - Self-hosted mesh VPN components
- `.statik/` - Configuration and key management

**Features**:
- VS Code server with extensions
- GitHub Copilot integration
- Mesh VPN for secure networking
- Persistent key management
- Automatic service discovery

### 📜 scripts/
**Purpose**: System management and automation scripts

**Key Components**:
- `start-statik-system.sh` - Launch complete system
- `start_mobile_mirror.sh` - Backend-only launcher
- `mobile_cli.sh` - GUI management interface
- `stop-statik-system.sh` - Clean system shutdown

**Features**:
- Automated service startup
- GUI management interface
- Clean shutdown procedures
- Service health monitoring
- Error handling and recovery

### ⚙️ env/
**Purpose**: Environment setup and dependency management

**Key Components**:
- `install.sh` - Main installation script
- `requirements.txt` - Python dependencies
- `environment.yml` - Conda environment
- `setup/` - Specialized setup scripts

**Features**:
- Automated installation
- Dependency resolution
- Environment configuration
- System requirement checking

## 🔐 Security Structure

### Authentication & Keys
```
.statik/keys/
├── github-token          # GitHub API access
├── codetoken            # VS Code server authentication
└── preauth-keys/        # Mobile device pre-authentication
    ├── mobile-device-1  # Device-specific keys
    ├── mobile-device-2
    └── ...
```

### Configuration Security
```
.statik/config/
├── headscale.yaml       # Mesh VPN configuration
├── acl.yaml            # Network access control
└── auth/               # Authentication configuration
    └── tokens.conf     # Stored authentication tokens
```

## 📊 Logging Structure

### Log Organization
```
logs/                           # System logs
├── mobilemirror.log           # Main application log (JSON structured)
├── errors.log                 # Error-only log for monitoring
├── security.log               # Security events and audit trail
├── performance.log            # Performance metrics and timing
└── component-logs/            # Component-specific logs
    ├── backend/               # Backend service logs
    ├── statik-server/         # VS Code server logs
    └── mesh-vpn/              # VPN service logs
```

### Log Rotation
- **Size**: 10MB maximum per log file
- **Retention**: 5 backup files per log
- **Format**: Structured JSON with human-readable fallback
- **Monitoring**: Automatic error alerting and metrics

## 🔧 Configuration Management

### Environment Variables
```bash
# Core Configuration
MOBILEMIRROR_TOKEN=secure-token
GITHUB_TOKEN=ghp_token
PORT=8000
HOST=0.0.0.0

# Feature Toggles
ENABLE_SCREEN_STREAMING=true
ENABLE_TERMINAL_ACCESS=true
ENABLE_MOUSE_INPUT=true
COPILOT_ENABLED=true

# Security Settings
MAX_FAILED_ATTEMPTS=5
LOCKOUT_DURATION=300
LOG_LEVEL=INFO
```

### Configuration Files
```
.vscode/settings.json          # Python interpreter configuration
.env                          # Environment variables
environment.yml               # Conda environment specification
requirements.txt              # Python dependencies
```

## 🚀 Runtime Structure

### Active Services
```
System Runtime:
├── FastAPI Backend (Port 8000)    # Mobile Mirror API
├── VS Code Server (Port 8080)     # Development environment
├── VNC Server (Port 5901)         # Screen streaming
├── Headscale VPN (Port 8080)      # Mesh networking
└── Logging Services               # Centralized logging
```

### Process Hierarchy
```
start-statik-system.sh
├── Mobile Mirror Backend
│   ├── FastAPI Server (uvicorn)
│   ├── WebSocket Terminal Bridge
│   ├── Screen Streamer (x11vnc)
│   └── Mouse Input Handler
├── Statik Server
│   ├── VS Code Server
│   ├── GitHub Copilot
│   └── Extension Manager
└── Mesh VPN
    ├── Headscale Server
    ├── Peer Management
    └── Network Configuration
```

## 📈 Development Structure

### Code Organization
```
Source Code Quality:
├── Type Hints: Full Python type annotations
├── Docstrings: Comprehensive function documentation
├── Error Handling: Robust exception management
├── Logging: Comprehensive audit trail
├── Testing: Unit and integration tests
└── Security: Input validation and sanitization
```

### Development Tools
```
.vscode/
├── settings.json              # IDE configuration
├── launch.json               # Debug configurations  
├── tasks.json                # Build and run tasks
└── extensions.json           # Recommended extensions
```

## 🔍 Monitoring & Observability

### Health Checks
```
Monitoring Endpoints:
├── GET /health                # System health status
├── GET /stats/logs           # Logging statistics
├── GET /stats/auth           # Authentication metrics
├── GET /stats/performance    # Performance metrics
└── GET /stats/security       # Security event summary
```

### Metrics Collection
```
Performance Monitoring:
├── Request timing and latency
├── Resource usage (CPU, memory, disk)
├── Connection counts and quality
├── Error rates and patterns
├── Security events and threats
└── System health indicators
```

## 🎯 Usage Patterns

### Development Workflow
```
Typical Development Session:
1. ./scripts/start-statik-system.sh    # Start complete system
2. Access VS Code at localhost:8080    # Development environment
3. Connect mobile via QR code          # Mobile interface
4. Use touch controls for interaction  # Mobile → Desktop
5. Monitor via logging endpoints       # System health
6. ./scripts/stop-statik-system.sh     # Clean shutdown
```

### Mobile Integration
```
Mobile Connection Flow:
1. Scan QR code or direct connection
2. Authenticate with token
3. Access file system via API
4. Use terminal via WebSocket
5. Control mouse via touch
6. View desktop via VNC stream
```

## 🔧 Maintenance

### Regular Maintenance
```bash
# Log cleanup (automated via rotation)
find logs/ -name "*.log.*" -mtime +30 -delete

# Key rotation (monthly recommended)
./scripts/rotate-keys.sh

# System updates
./env/update-dependencies.sh

# Health monitoring
./scripts/system-health-check.sh
```

### Backup Strategy
```
Critical Data:
├── .statik/keys/             # Authentication keys (encrypted backup)
├── .statik/config/           # Configuration files
├── logs/                     # Recent logs (for debugging)
└── .vscode/settings.json     # Development environment
```

This project tree represents a comprehensive, production-ready mobile development streaming solution with enterprise-grade security, monitoring, and maintainability. 🚀
