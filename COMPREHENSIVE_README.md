# 🔥 Mobile Mirror - Complete Project Documentation

## 📋 Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)  
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Security](#security)
- [Monitoring & Logging](#monitoring--logging)
- [Development](#development)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🎯 Overview

Mobile Mirror is a comprehensive desktop development environment streaming system that enables secure mobile access to your development workspace. It combines a FastAPI backend with integrated VS Code server and self-hosted mesh VPN for a complete sovereign development solution.

### Key Components
- **Mobile Mirror Backend**: FastAPI server for mobile-desktop interaction
- **Statik Server**: VS Code server with GitHub Copilot integration
- **Headscale Mesh VPN**: Self-hosted Tailscale alternative for secure networking
- **Centralized Logging**: Comprehensive monitoring and audit system

## 🏗️ Architecture

```
Mobile-Mirror/
├── 📱 mobilemirror/           # Core mobile mirror application
│   ├── backend/               # FastAPI backend server
│   │   ├── app.py            # Main API application
│   │   ├── file_ops.py       # File system operations
│   │   ├── terminal_bridge.py # WebSocket terminal access
│   │   ├── mouse_input.py    # Mouse input simulation
│   │   ├── screen_streamer.py # VNC desktop streaming
│   │   └── utils/            # Utility modules
│   │       ├── logger.py     # Centralized logging system
│   │       ├── auth.py       # Authentication & security
│   │       └── qr_generator.py # QR code generation
│   └── __init__.py
├── 🖥️ statik-server/         # VS Code server integration
│   ├── startup.sh            # Main server launcher
│   ├── mesh-start.sh         # VPN initialization
│   ├── internal/mesh/        # Headscale mesh VPN
│   └── .statik/              # Configuration & keys
├── 📜 scripts/               # System management scripts
│   ├── start-statik-system.sh # Complete system launcher
│   ├── start_mobile_mirror.sh # Backend-only launcher
│   ├── mobile_cli.sh         # GUI management interface
│   └── stop-statik-system.sh # System shutdown
├── 📚 docs/                  # Documentation
├── 🧪 demos/                 # Example configurations
├── 📊 logs/                  # System logs
└── ⚙️ env/                   # Environment setup
```

## ✨ Features

### 🔐 Security & Authentication
- **Token-based Authentication**: Secure API access with rate limiting
- **Mesh VPN Integration**: Encrypted peer-to-peer networking
- **IP Blocking**: Automatic blocking after failed attempts
- **Audit Logging**: Comprehensive security event tracking
- **No Cloud Dependencies**: Completely self-hosted solution

### 📱 Mobile Integration
- **Real-time Desktop Streaming**: VNC-based screen sharing
- **Touch-to-Mouse Translation**: Mobile touch → desktop mouse
- **File System Access**: Secure remote file operations
- **Terminal Access**: Full shell access via WebSocket
- **QR Code Connection**: Easy mobile device onboarding

### 💻 Development Environment
- **VS Code Server**: Full IDE with extensions support
- **GitHub Copilot**: AI-powered code assistance
- **Multi-language Support**: Python, JavaScript, TypeScript, etc.
- **Integrated Terminal**: Direct system access
- **Extension Management**: Full VS Code marketplace access

### 🌐 Networking
- **Mesh VPN**: Headscale-based secure networking
- **Zero-Config**: Automatic peer discovery
- **Persistent Keys**: Pre-authentication for mobile devices
- **Cross-platform**: Works on Linux, macOS, Windows, mobile

### 📊 Monitoring & Logging
- **Centralized Logging**: Structured JSON logging system
- **Performance Monitoring**: Request timing and resource usage
- **Security Monitoring**: Failed attempts and intrusion detection
- **Health Checks**: System status and component monitoring

## 🚀 Installation

### Prerequisites
```bash
# System dependencies
sudo apt update && sudo apt install -y \
    x11vnc xdotool qrencode \
    golang-go nodejs npm \
    python3 python3-pip

# VS Code dependencies
curl -fsSL https://code-server.dev/install.sh | sh
```

### Quick Setup
```bash
# Clone repository
git clone https://github.com/statikfintechllc/Mobile-Mirror.git
cd Mobile-Mirror

# Run installation
./env/install.sh

# Start complete system
./scripts/start-statik-system.sh
```

### Manual Installation
```bash
# 1. Setup Python environment
conda env create -f environment.yml
conda activate Mob-Dev

# 2. Install Python dependencies
pip install -r requirements.txt

# 3. Build statik-server
cd statik-server && ./build.sh && cd ..

# 4. Configure authentication
export MOBILEMIRROR_TOKEN="your-secure-token"

# 5. Start services
./scripts/start_mobile_mirror.sh    # Backend only
./scripts/start-statik-system.sh    # Complete system
```

## 🎮 Usage

### Starting the System

#### Complete System (Recommended)
```bash
./scripts/start-statik-system.sh
```
**Provides**:
- Mobile Mirror API: `http://localhost:8000`
- VS Code Server: `http://localhost:8080` 
- Mesh VPN: Automatic peer networking
- Desktop Streaming: VNC on port 5901

#### Backend Only
```bash
./scripts/start_mobile_mirror.sh
```
**Provides**:
- Mobile Mirror API: `http://localhost:8000`
- File operations and terminal access
- Mouse input simulation

### Mobile Connection

#### Method 1: QR Code (Easiest)
1. Start the system
2. Visit: `http://localhost:8000/qr`
3. Scan QR code with mobile device
4. Access the interface in mobile browser

#### Method 2: Direct Connection
1. Find your IP address: `ip addr show`
2. Connect mobile to same network
3. Visit: `http://YOUR_IP:8000`

#### Method 3: Mesh VPN (Most Secure)
1. System generates pre-auth keys automatically
2. Install Tailscale/Headscale client on mobile
3. Use generated key to join mesh network
4. Access via mesh IP address

### API Usage

#### Authentication
```bash
# Set authentication token
export AUTH_TOKEN="your-token"

# All requests require Authorization header
curl -H "Authorization: $AUTH_TOKEN" http://localhost:8000/
```

#### File Operations
```bash
# List files
curl -H "Authorization: $AUTH_TOKEN" \
     "http://localhost:8000/files?path=/home/user"

# Read file
curl -H "Authorization: $AUTH_TOKEN" \
     -X POST "http://localhost:8000/read" \
     -H "Content-Type: application/json" \
     -d '{"path": "/path/to/file.txt"}'

# Write file
curl -H "Authorization: $AUTH_TOKEN" \
     -X PUT "http://localhost:8000/write" \
     -H "Content-Type: application/json" \
     -d '{"path": "/path/to/file.txt", "content": "Hello World"}'
```

#### Mouse Control
```bash
# Move mouse
curl -H "Authorization: $AUTH_TOKEN" \
     -X POST "http://localhost:8000/mouse" \
     -H "Content-Type: application/json" \
     -d '{"x": 100, "y": 200}'

# Click at position
curl -H "Authorization: $AUTH_TOKEN" \
     -X POST "http://localhost:8000/mouse" \
     -H "Content-Type: application/json" \
     -d '{"x": 100, "y": 200, "click": true}'
```

#### Terminal Access (WebSocket)
```javascript
// JavaScript WebSocket connection
const ws = new WebSocket('ws://localhost:8000/terminal');

ws.onopen = function() {
    console.log('Terminal connected');
    ws.send('ls -la\\n'); // Send command
};

ws.onmessage = function(event) {
    console.log('Terminal output:', event.data);
};
```

## ⚙️ Configuration

### Environment Variables
```bash
# Authentication
MOBILEMIRROR_TOKEN=your-secure-token-here
GITHUB_TOKEN=ghp_your_github_token_here

# Server Configuration
PORT=8000
HOST=0.0.0.0
COPILOT_ENABLED=true

# Logging
LOG_LEVEL=INFO
JSON_FORMAT=true

# Features
ENABLE_SCREEN_STREAMING=true
ENABLE_TERMINAL_ACCESS=true
ENABLE_MOUSE_INPUT=true

# Security
MAX_FAILED_ATTEMPTS=5
LOCKOUT_DURATION=300
```

### Configuration Files

#### Authentication Tokens
```bash
# Location: ~/.local/share/mobilemirror/auth/tokens.conf
# Format: name:hash:salt:timestamp
mobile-device-1:hashed_token:salt:1640995200
desktop-client:hashed_token:salt:1640995300
```

#### Headscale Configuration
```yaml
# Location: statik-server/.statik/config/headscale.yaml
server_url: http://127.0.0.1:8080
listen_addr: 127.0.0.1:8080
metrics_listen_addr: 127.0.0.1:9090
database_type: sqlite3
database_sqlite:
  path: /tmp/headscale.db
```

#### VS Code Settings
```json
// Location: statik-server/.statik/vscode/settings.json
{
    "python.defaultInterpreterPath": "/path/to/conda/envs/Mob-Dev/bin/python",
    "github.copilot.enable": true,
    "terminal.integrated.shell.linux": "/bin/bash"
}
```

## 🔒 Security

### Authentication Security
- **Strong Tokens**: Use 32+ character random tokens
- **Token Rotation**: Regularly update authentication tokens
- **Rate Limiting**: 50 requests/second, 1000/minute per IP
- **IP Blocking**: Automatic blocking after 5 failed attempts
- **Timing Attack Protection**: Constant-time comparisons

### Network Security
- **Mesh VPN**: All traffic encrypted via WireGuard
- **No Cloud Dependencies**: Completely self-hosted
- **Firewall Rules**: Restrict access to necessary ports
- **HTTPS**: Use reverse proxy with SSL in production

### System Security
- **Minimal Privileges**: Run services with least required permissions
- **File System Protection**: Path traversal prevention
- **Command Auditing**: All terminal commands logged
- **Resource Limits**: Prevent resource exhaustion attacks

### Production Deployment
```bash
# Use HTTPS reverse proxy
sudo apt install nginx certbot
# Configure SSL certificates and proxy settings

# Restrict network access
sudo ufw allow 22/tcp     # SSH only
sudo ufw allow 80/tcp     # HTTP redirect
sudo ufw allow 443/tcp    # HTTPS
sudo ufw enable

# Run services as non-root user
sudo adduser mobilemirror
sudo -u mobilemirror ./scripts/start-statik-system.sh
```

## 📊 Monitoring & Logging

### Log Locations
```
~/.local/share/mobilemirror/logs/
├── mobilemirror.log          # Main application log
├── errors.log                # Error-only log
├── security.log              # Security events (future)
└── performance.log           # Performance metrics (future)
```

### Log Formats

#### Structured JSON Logging
```json
{
  "timestamp": "2024-01-15T10:30:00.123Z",
  "level": "INFO",
  "module": "mobilemirror.backend.app",
  "message": "API request processed",
  "request_id": "req_123456",
  "client_ip": "192.168.1.100",
  "endpoint": "/files",
  "response_time": 0.045,
  "status_code": 200
}
```

#### Human-Readable Format
```
[2024-01-15 10:30:00] [mobilemirror.backend.app] [INFO] API request processed (app.py:42)
```

### Monitoring Endpoints
```bash
# System health
curl http://localhost:8000/health

# Log statistics  
curl http://localhost:8000/stats/logs

# Authentication metrics
curl http://localhost:8000/stats/auth

# Performance metrics
curl http://localhost:8000/stats/performance
```

### Performance Monitoring
- **Request Timing**: All API calls timed automatically
- **Resource Usage**: CPU, memory, disk usage tracking
- **Connection Monitoring**: Active sessions and bandwidth
- **Error Rates**: Failed requests and error patterns

### Security Monitoring
- **Failed Authentication**: Login attempts and sources
- **Blocked IPs**: Rate-limited and banned addresses  
- **Suspicious Activity**: Unusual access patterns
- **Audit Trail**: All administrative actions logged

## 🛠️ Development

### Development Setup
```bash
# Clone and setup
git clone https://github.com/statikfintechllc/Mobile-Mirror.git
cd Mobile-Mirror

# Create development environment
conda env create -f environment.yml
conda activate Mob-Dev

# Install development dependencies
pip install -r requirements-dev.txt

# Setup pre-commit hooks
pre-commit install
```

### Testing
```bash
# Run all tests
python -m pytest

# Run with coverage
python -m pytest --cov=mobilemirror --cov-report=html

# Run specific test modules
python -m pytest tests/backend/
python -m pytest tests/utils/
python -m pytest tests/integration/
```

### Code Quality
```bash
# Linting
pylint mobilemirror/
flake8 mobilemirror/

# Type checking
mypy mobilemirror/

# Formatting
black mobilemirror/
isort mobilemirror/

# Security scanning
bandit -r mobilemirror/
```

### Adding New Features

#### 1. Add Logging
```python
from mobilemirror.backend.utils.logger import get_logger, log_performance

logger = get_logger(__name__)

@log_performance
def new_feature():
    logger.info("Starting new feature")
    try:
        # Implementation
        logger.info("Feature completed successfully")
    except Exception as e:
        logger.error("Feature failed", exc_info=True)
        raise
```

#### 2. Add Authentication
```python
from mobilemirror.backend.utils.auth import verify_token

def protected_endpoint(request: Request):
    token = request.headers.get("Authorization", "")
    client_ip = request.client.host if request.client else "unknown"
    
    if not verify_token(token, client_ip):
        raise HTTPException(status_code=403, detail="Authentication required")
```

#### 3. Add API Documentation
```python
@app.post("/new-endpoint", 
         summary="Brief description",
         description="Detailed description",
         response_model=ResponseModel,
         responses={
             200: {"description": "Success"},
             403: {"description": "Authentication failed"},
             500: {"description": "Server error"}
         })
def new_endpoint():
    pass
```

## 🐛 Troubleshooting

### Common Issues

#### Installation Problems
```bash
# Python environment issues
conda info --envs  # Check environments
conda activate Mob-Dev  # Activate environment
which python  # Verify Python path

# System dependencies missing
sudo apt install x11vnc xdotool qrencode  # Install tools
which x11vnc xdotool qrencode  # Verify installation

# Permission errors
chmod +x scripts/*.sh  # Make scripts executable
chown -R $USER:$USER ~/.local/share/mobilemirror/  # Fix ownership
```

#### Connection Issues
```bash
# Check service status
systemctl status code-server  # VS Code server
ps aux | grep uvicorn  # FastAPI server
ps aux | grep x11vnc  # VNC server
ps aux | grep headscale  # Mesh VPN

# Check network connectivity
netstat -tlnp | grep :8000  # API server
netstat -tlnp | grep :8080  # VS Code server
netstat -tlnp | grep :5901  # VNC server

# Test API endpoints
curl http://localhost:8000/  # Health check
curl -H "Authorization: token" http://localhost:8000/files  # Auth test
```

#### Authentication Problems
```bash
# Check token configuration
echo $MOBILEMIRROR_TOKEN  # Environment variable
cat ~/.local/share/mobilemirror/auth/tokens.conf  # Stored tokens

# Check authentication logs
tail -f ~/.local/share/mobilemirror/logs/mobilemirror.log | grep auth

# Reset authentication
rm ~/.local/share/mobilemirror/auth/tokens.conf  # Clear stored tokens
export MOBILEMIRROR_TOKEN="new-secure-token"  # Set new token
```

#### Performance Issues
```bash
# Check resource usage
htop  # System resources
iotop  # Disk I/O
nethogs  # Network usage

# Check log file sizes
du -sh ~/.local/share/mobilemirror/logs/  # Log directory size
ls -lah ~/.local/share/mobilemirror/logs/  # Individual files

# Monitor API performance
curl -w "@curl-format.txt" http://localhost:8000/files
```

### Debugging

#### Enable Debug Logging
```bash
# Temporary debug mode
export LOG_LEVEL=DEBUG
./scripts/start_mobile_mirror.sh

# Permanent debug configuration
echo 'LOG_LEVEL=DEBUG' >> ~/.bashrc
```

#### Component Testing
```bash
# Test individual components
python -c "from mobilemirror.backend.utils.logger import get_logger; print('Logging OK')"
python -c "from mobilemirror.backend.utils.auth import verify_token; print('Auth OK')"  
python -c "from mobilemirror.backend.utils.qr_generator import generate_qr; print('QR OK')"

# Test API endpoints
curl http://localhost:8000/docs  # API documentation
curl http://localhost:8000/health  # Health check
```

#### Log Analysis
```bash
# View recent errors
tail -n 100 ~/.local/share/mobilemirror/logs/errors.log

# Search for specific issues
grep -i "error" ~/.local/share/mobilemirror/logs/mobilemirror.log
grep -i "authentication" ~/.local/share/mobilemirror/logs/mobilemirror.log
grep -i "connection" ~/.local/share/mobilemirror/logs/mobilemirror.log

# Monitor live logs
tail -f ~/.local/share/mobilemirror/logs/mobilemirror.log
```

## 🤝 Contributing

### Getting Started
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes following the coding standards
4. Add tests for new functionality
5. Update documentation
6. Submit a pull request

### Coding Standards
- **Python**: Follow PEP 8 and use type hints
- **Logging**: Add comprehensive logging to all new features
- **Error Handling**: Include proper exception handling
- **Testing**: Write unit tests for new code
- **Documentation**: Update READMEs and docstrings

### Pull Request Process
1. Ensure all tests pass: `python -m pytest`
2. Update documentation for new features
3. Add your changes to the CHANGELOG
4. Request review from maintainers
5. Address feedback and merge

### Code Review Checklist
- [ ] Code follows style guidelines
- [ ] All tests pass
- [ ] New features have tests
- [ ] Documentation is updated
- [ ] Security considerations addressed
- [ ] Logging is comprehensive
- [ ] Error handling is robust

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **FastAPI**: Modern Python web framework
- **VS Code**: Excellent development environment
- **Headscale**: Self-hosted Tailscale alternative
- **GitHub Copilot**: AI-powered development assistance
- **Open Source Community**: For all the amazing tools and libraries

## 📞 Support

- **Documentation**: Check the comprehensive READMEs in each module
- **Issues**: Report bugs and feature requests on GitHub
- **Discussions**: Community support and questions
- **Security**: Report security issues privately to maintainers

---

**Mobile Mirror** - Bringing your desktop development environment to your mobile device with security, performance, and sovereignty. 🚀
