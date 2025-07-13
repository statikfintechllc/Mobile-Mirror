# Mobile Mirror Backend

## Overview

The Mobile Mirror Backend is a comprehensive FastAPI-based server that enables secure mobile access to desktop development environments. It provides real-time desktop streaming, file operations, terminal access, and mouse input simulation through a modern REST API and WebSocket interface.

## Architecture

```
mobilemirror/backend/
├── app.py                 # Main FastAPI application and API routes
├── file_ops.py           # Secure file system operations
├── terminal_bridge.py    # WebSocket terminal access via PTY
├── mouse_input.py        # Mouse input simulation with xdotool
├── screen_streamer.py    # VNC-based desktop streaming
├── __init__.py          # Package initialization
└── utils/               # Utility modules
    ├── auth.py          # Authentication and security
    ├── logger.py        # Centralized logging system
    ├── qr_generator.py  # QR code generation for mobile access
    └── __init__.py      # Utils package initialization
```

## Core Features

### 🔐 Security & Authentication
- Token-based authentication with rate limiting
- IP blocking for failed attempts  
- Comprehensive audit logging
- Secure token generation and validation
- Protection against timing attacks

### 📁 File Operations
- Secure directory browsing with permission checks
- File reading/writing with backup and validation
- Binary file support with encoding detection
- Path traversal protection
- Comprehensive error handling

### 💻 Terminal Access
- Real-time WebSocket terminal connections
- PTY (pseudo-terminal) management
- Session isolation and cleanup
- Command auditing and logging
- Resource monitoring and limits

### 🖱️ Mouse Input
- Cross-platform mouse simulation via xdotool
- Coordinate validation and bounds checking
- Rate limiting to prevent abuse
- Screen resolution detection
- Support for multiple mouse buttons

### 📺 Screen Streaming
- VNC-based desktop streaming
- Multiple quality levels
- Connection monitoring
- Automatic process management
- Performance optimization

### 📱 Mobile Integration
- QR code generation for easy connection
- Connection metadata and instructions
- Mobile-optimized API responses
- Touch-to-mouse translation

## API Endpoints

### Core Endpoints
- `GET /` - Health check and system status
- `GET /docs` - Interactive API documentation
- `GET /log` - Recent log entries for debugging

### File Operations
- `GET /files?path={path}` - List directory contents
- `POST /read` - Read file contents
- `PUT /write` - Write file contents
- `DELETE /files` - Delete files/directories

### System Access
- `WebSocket /terminal` - Real-time terminal access
- `GET /screen` - Screen streaming status
- `POST /mouse` - Mouse input simulation
- `GET /qr` - Generate connection QR code

## Configuration

### Environment Variables
```bash
# Authentication
MOBILEMIRROR_TOKEN=your-secure-token

# Server Configuration  
PORT=8000
HOST=0.0.0.0

# Logging
LOG_LEVEL=INFO
LOG_DIR=~/.local/share/mobilemirror/logs

# Features
ENABLE_SCREEN_STREAMING=true
ENABLE_TERMINAL_ACCESS=true
```

### Dependencies
```
fastapi>=0.100.0
uvicorn>=0.20.0
websockets>=10.0
python-multipart>=0.0.5
pillow>=9.0.0
qrcode[pil]>=7.0.0
psutil>=5.8.0
python-jose[cryptography]>=3.3.0
passlib[bcrypt]>=1.7.4
python-dotenv>=0.19.0
```

### System Requirements
- Python 3.10+
- X11 display server (for screen streaming)
- xdotool (for mouse input)
- x11vnc (for screen streaming)
- qrencode (optional, for QR codes)

## Installation

1. Install system dependencies:
```bash
sudo apt update
sudo apt install x11vnc xdotool qrencode
```

2. Install Python dependencies:
```bash
pip install -r requirements.txt
```

3. Configure authentication:
```bash
export MOBILEMIRROR_TOKEN="your-secure-token"
```

## Usage

### Starting the Server
```bash
# Direct Python execution
python -m mobilemirror.backend.app

# Using uvicorn
uvicorn mobilemirror.backend.app:app --host 0.0.0.0 --port 8000

# Using the provided script
./scripts/start_mobile_mirror.sh
```

### Mobile Connection
1. Start the server
2. Generate QR code: `GET /qr`
3. Scan QR code with mobile device
4. Access the web interface from mobile browser

### API Usage Examples
```python
import requests

# Authenticate
headers = {"Authorization": "your-token"}

# List files
response = requests.get("http://localhost:8000/files", headers=headers)
files = response.json()

# Read file
response = requests.post("http://localhost:8000/read", 
                        json={"path": "/path/to/file"}, 
                        headers=headers)
content = response.json()["content"]

# Simulate mouse click
response = requests.post("http://localhost:8000/mouse",
                        json={"x": 100, "y": 200, "click": true},
                        headers=headers)
```

## Logging

The backend uses a comprehensive centralized logging system:

### Log Levels
- **DEBUG**: Detailed debugging information
- **INFO**: General operational messages
- **WARNING**: Warning conditions
- **ERROR**: Error conditions
- **CRITICAL**: Critical system failures

### Log Files
- `~/.local/share/mobilemirror/logs/mobilemirror.log` - Main application log
- `~/.local/share/mobilemirror/logs/errors.log` - Error-only log
- Log rotation: 10MB max size, 5 backup files

### Structured Logging
All logs include:
- Timestamp
- Module name
- Log level
- Message
- Additional metadata (JSON format)
- Stack traces for errors

## Security Considerations

### Authentication
- Use strong, unique tokens
- Regularly rotate authentication tokens
- Monitor failed authentication attempts
- Enable IP blocking for security

### Network Security
- Use HTTPS in production
- Implement firewall rules
- Consider VPN access for sensitive environments
- Monitor network connections

### System Security
- Run with minimal required privileges
- Monitor file system access
- Audit terminal commands
- Limit resource usage

## Monitoring & Metrics

### Performance Monitoring
- Request response times
- Resource usage (CPU, memory)
- Connection counts
- Error rates

### Security Monitoring
- Failed authentication attempts
- Blocked IP addresses
- Suspicious activity patterns
- Access patterns

### System Health
- Service uptime
- Connection quality
- Resource availability
- Error frequencies

## Troubleshooting

### Common Issues

**Import Errors**
- Ensure all dependencies are installed
- Check Python environment activation
- Verify package installation

**Permission Errors**
- Check file system permissions
- Verify X11 display access
- Ensure xdotool is installed

**Connection Issues**
- Verify firewall settings
- Check network connectivity
- Validate authentication tokens
- Review server logs

### Debugging
1. Enable debug logging: `LOG_LEVEL=DEBUG`
2. Check log files for errors
3. Verify system dependencies
4. Test individual components
5. Use API documentation at `/docs`

## Development

### Testing
```bash
# Run tests
python -m pytest tests/

# Run with coverage
python -m pytest --cov=mobilemirror tests/
```

### Code Quality
```bash
# Linting
pylint mobilemirror/

# Type checking
mypy mobilemirror/

# Formatting
black mobilemirror/
```

### Contributing
1. Follow PEP 8 style guidelines
2. Add comprehensive logging
3. Include error handling
4. Write tests for new features
5. Update documentation

## License

This project is licensed under the MIT License. See LICENSE file for details.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review log files for errors
3. Consult API documentation at `/docs`
4. Report issues with detailed logs and reproduction steps
