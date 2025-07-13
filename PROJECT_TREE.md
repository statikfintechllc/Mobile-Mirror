# 🌳 Mobile Mirror - Complete Project Tree

## 📋 Project Structure Overview

```
Mobile-Mirror/                           # 🏠 Root project directory
├── 📱 mobilemirror/                     # Core Mobile Mirror application
│   ├── __init__.py                      # Package initialization
│   └── backend/                         # 🚀 FastAPI backend server
│       ├── __init__.py                  # Backend package init
│       ├── README.md                    # Backend documentation  
│       ├── app.py                       # 🌐 Main FastAPI application & API routes
│       ├── file_ops.py                  # 📁 Secure file system operations
│       ├── terminal_bridge.py           # 💻 WebSocket terminal access via PTY
│       ├── mouse_input.py               # 🖱️ Mouse input simulation with xdotool
│       ├── screen_streamer.py           # 📺 VNC-based desktop streaming
│       └── utils/                       # 🛠️ Utility modules
│           ├── __init__.py              # Utils package init
│           ├── README.md                # Utils documentation
│           ├── logger.py                # 📝 Centralized logging system
│           ├── auth.py                  # 🔐 Authentication & security
│           └── qr_generator.py          # 📱 QR code generation for mobile access
│
├── 🖥️ statik-server/                   # VS Code server with mesh VPN integration
│   ├── startup.sh                       # 🚀 Main server launcher script
│   ├── mesh-start.sh                    # 🌐 VPN initialization script
│   ├── build.sh                         # 🔨 Build script for statik-server
│   ├── internal/                        # Internal components
│   │   └── mesh/                        # 🔒 Headscale mesh VPN
│   │       ├── headscale                # Compiled headscale binary
│   │       ├── headscale.sh             # VPN startup script
│   │       └── config/                  # VPN configuration files
│   └── .statik/                         # 🔧 Configuration & keys directory
│       ├── config/                      # System configuration
│       │   ├── headscale.yaml           # Headscale mesh configuration
│       │   └── acl.yaml                 # Access control list
│       ├── keys/                        # 🔑 Authentication keys storage
│       │   ├── github-token             # GitHub authentication
│       │   ├── codetoken                # VS Code access token
│       │   └── preauth-keys/            # Pre-authentication keys for devices
│       ├── db/                          # Database files
│       ├── data/                        # Runtime data
│       ├── logs/                        # Component logs
│       ├── extensions/                  # VS Code extensions
│       └── userdata/                    # VS Code user data
│
├── 📜 scripts/                          # 🔧 System management scripts
│   ├── start-statik-system.sh           # 🚀 Complete system launcher
│   ├── stop-statik-system.sh            # 🛑 System shutdown script
│   ├── start_mobile_mirror.sh           # 📱 Backend-only launcher
│   ├── mobile_cli.sh                    # 🖥️ GUI management interface
│   ├── start_code.sh                    # VS Code server launcher
│   ├── stop_code.sh                     # VS Code server shutdown
│   └── remove_mobile.sh                 # 🗑️ Cleanup/uninstall script
│
├── 📚 docs/                             # 📖 Documentation
│   ├── API.md                           # API documentation
│   ├── INSTALLATION.md                  # Installation guide
│   ├── CONFIGURATION.md                 # Configuration guide
│   ├── SECURITY.md                      # Security guidelines
│   └── TROUBLESHOOTING.md               # Troubleshooting guide
│
├── 🧪 demos/                            # 🎯 Example configurations & demos
│   ├── mobile-client/                   # Mobile client examples
│   ├── api-examples/                    # API usage examples
│   └── integration-tests/               # Integration test scenarios
│
├── ⚙️ env/                              # 🌍 Environment setup
│   ├── install.sh                       # 🔧 Main installation script
│   ├── requirements.txt                 # 📦 Python dependencies
│   ├── environment.yml                  # 🐍 Conda environment definition
│   └── setup/                           # Setup utilities
│       ├── python-setup.sh              # Python environment setup
│       ├── system-deps.sh               # System dependencies installer
│       └── vscode-setup.sh              # VS Code configuration
│
├── 📊 logs/                             # 📈 System logs (created at runtime)
│   ├── mobilemirror.log                 # Main application log
│   ├── errors.log                       # Error-only log
│   ├── security.log                     # Security events
│   └── performance.log                  # Performance metrics
│
├── 🧱 .github/                          # GitHub configuration
│   ├── workflows/                       # CI/CD workflows
│   │   ├── tests.yml                    # Test automation
│   │   ├── security.yml                 # Security scanning
│   │   └── docs.yml                     # Documentation updates
│   ├── ISSUE_TEMPLATE/                  # Issue templates
│   └── PULL_REQUEST_TEMPLATE.md         # PR template
│
├── 🔧 .vscode/                          # VS Code workspace configuration
│   ├── settings.json                    # Python interpreter & project settings
│   ├── launch.json                      # Debug configurations
│   ├── tasks.json                       # Build & run tasks
│   └── extensions.json                  # Recommended extensions
│
├── 📄 Root Files                        # 📋 Project configuration files
├── .env                                 # Environment variables
├── .python-version                      # Python version specification
├── .gitignore                           # Git ignore rules
├── LICENSE                              # MIT license
├── COMPREHENSIVE_README.md              # 📚 Complete project documentation
├── SYSTEM_STATUS.md                     # 🔋 System status & completion summary
├── STATIK_SYSTEM_README.md              # 🖥️ Statik server documentation
└── PROJECT_TREE.md                     # 🌳 This file - project structure
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
