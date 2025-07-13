# Mobile Mirror Backend Utils

## Overview

The utils package provides essential utility modules for the Mobile Mirror backend, including centralized logging, authentication, and QR code generation. These modules are designed to be secure, performant, and highly configurable.

## Modules

### 📝 logger.py - Centralized Logging System

**Purpose**: Comprehensive logging infrastructure with structured logging, performance monitoring, and audit capabilities.

**Features**:
- Multiple log levels (DEBUG, INFO, WARNING, ERROR, CRITICAL)
- JSON structured logging support
- Automatic log rotation (10MB max, 5 backups)
- Performance monitoring decorators
- API request/response logging
- Separate error log file
- Thread-safe logger registry

**Usage**:
```python
from mobilemirror.backend.utils.logger import get_logger, log_performance, log_api_request

# Get a module-specific logger
logger = get_logger(__name__)

# Basic logging
logger.info("Operation completed successfully")
logger.error("An error occurred", exc_info=True)

# Performance monitoring decorator
@log_performance
def slow_operation():
    # Function execution time will be logged
    pass

# API endpoint logging decorator
@log_api_request
def api_endpoint():
    # Request/response details will be logged
    pass
```

**Configuration**:
- Log files: `~/.local/share/mobilemirror/logs/`
- JSON format: Configurable via `JSON_FORMAT` variable
- Log levels: Configurable per logger
- Rotation: 10MB max size, 5 backup files

---

### 🔐 auth.py - Authentication & Security

**Purpose**: Secure authentication system with token validation, rate limiting, and security monitoring.

**Features**:
- Token-based authentication with secure hashing
- Rate limiting (50/second, 1000/minute)
- IP blocking after failed attempts
- Timing attack protection
- Secure token generation
- File-based token storage
- Comprehensive security audit logging

**Usage**:
```python
from mobilemirror.backend.utils.auth import verify_token, create_api_key, get_auth_stats

# Verify authentication token
is_valid = verify_token("user-token", "192.168.1.100")

# Create new API key
api_key = create_api_key("mobile-device-1", ["read", "write"])

# Get security statistics
stats = get_auth_stats()
```

**Security Features**:
- PBKDF2 password hashing with salt
- Timing attack protection using `hmac.compare_digest`
- Failed attempt tracking and IP blocking
- Secure token generation using `secrets` module
- Comprehensive audit logging

**Configuration**:
- Default token: `MOBILEMIRROR_TOKEN` environment variable
- Token file: `~/.local/share/mobilemirror/auth/tokens.conf`
- Rate limits: 50/second, 1000/minute per IP
- Lockout duration: 5 minutes

---

### 📱 qr_generator.py - QR Code Generation

**Purpose**: Generate QR codes for easy mobile device connection with multiple formats and styling options.

**Features**:
- Multiple generation methods (qrencode, Python qrcode)
- PNG and Base64 output formats
- Multiple sizes (small, medium, large)
- Error correction levels (L, M, Q, H)
- Styled QR codes (rounded corners)
- Connection metadata embedding
- URL validation and sanitization

**Usage**:
```python
from mobilemirror.backend.utils.qr_generator import generate_qr, get_qr_stats

# Generate basic QR code
qr_data = generate_qr("http://192.168.1.100:8000")

# Generate with options
qr_data = generate_qr(
    url="http://192.168.1.100:8000",
    format="base64",
    size="large",
    error_correction="H",
    style="rounded",
    include_metadata=True
)

# Get generation statistics
stats = get_qr_stats()
```

**Output Formats**:
- **PNG**: Raw image bytes
- **Base64**: Data URL for web embedding
- **Metadata**: Connection instructions and features

**Configuration**:
- Max URL length: 2048 characters
- Cache directory: `~/.local/share/mobilemirror/qr_cache/`
- Supported sizes: small (3), medium (6), large (10)
- Error correction: L, M, Q, H levels

## Installation

### System Dependencies
```bash
# For QR code generation
sudo apt install qrencode

# For mouse input (if using mouse_input module)
sudo apt install xdotool

# For screen streaming (if using screen_streamer module)
sudo apt install x11vnc
```

### Python Dependencies
```bash
pip install fastapi uvicorn qrcode[pil] psutil python-jose[cryptography] passlib[bcrypt]
```

## Configuration

### Environment Variables
```bash
# Authentication
MOBILEMIRROR_TOKEN=your-secure-token

# Logging
LOG_LEVEL=INFO
JSON_FORMAT=true

# Security
MAX_FAILED_ATTEMPTS=5
LOCKOUT_DURATION=300
```

### File Locations
```
~/.local/share/mobilemirror/
├── logs/
│   ├── mobilemirror.log     # Main log file
│   └── errors.log           # Error-only log
├── auth/
│   └── tokens.conf          # Stored authentication tokens
└── qr_cache/                # QR code cache (future feature)
```

## Security Considerations

### Authentication
- Use strong, unique tokens (32+ characters)
- Regularly rotate authentication tokens
- Monitor failed authentication attempts
- Enable IP blocking in production environments

### Logging
- Sensitive data is automatically redacted
- Logs include comprehensive audit trails
- Log files should be protected with appropriate permissions
- Consider log aggregation for production deployments

### QR Codes
- URL validation prevents malicious URLs
- Size limits prevent resource exhaustion
- Generated QR codes include connection metadata only
- No sensitive information is embedded in QR codes

## Monitoring

### Authentication Metrics
```python
from mobilemirror.backend.utils.auth import get_auth_stats

stats = get_auth_stats()
# Returns: blocked_ips, failed_attempts, stored_tokens, etc.
```

### Logging Metrics
```python
from mobilemirror.backend.utils.logger import get_log_stats

stats = get_log_stats()
# Returns: log_files, sizes, active_loggers, etc.
```

### QR Generation Metrics
```python
from mobilemirror.backend.utils.qr_generator import get_qr_stats

stats = get_qr_stats()
# Returns: tools_available, supported_formats, etc.
```

## Development

### Adding New Loggers
```python
# Always use get_logger for consistency
logger = get_logger(__name__)

# Use appropriate log levels
logger.debug("Detailed debugging info")
logger.info("General information")
logger.warning("Warning condition")
logger.error("Error occurred", exc_info=True)
logger.critical("Critical system failure")
```

### Adding Performance Monitoring
```python
@log_performance
def your_function():
    # Execution time automatically logged
    pass
```

### Adding API Logging
```python
@log_api_request
def your_api_endpoint():
    # Request/response automatically logged
    pass
```

## Troubleshooting

### Common Issues

**Logger Import Errors**
- Ensure proper relative imports: `from .logger import get_logger`
- Check package `__init__.py` files exist

**Authentication Failures**
- Verify token configuration
- Check for IP blocking
- Review authentication logs

**QR Generation Failures**
- Install qrencode: `sudo apt install qrencode`
- Install qrcode library: `pip install qrcode[pil]`
- Check URL validity

### Debugging
```python
# Enable debug logging
import logging
logging.basicConfig(level=logging.DEBUG)

# Check module status
from mobilemirror.backend.utils.logger import get_log_stats
from mobilemirror.backend.utils.auth import get_auth_stats
from mobilemirror.backend.utils.qr_generator import get_qr_stats

print("Logging:", get_log_stats())
print("Auth:", get_auth_stats())
print("QR:", get_qr_stats())
```

## Testing

### Unit Tests
```bash
# Test individual modules
python -m pytest tests/utils/test_logger.py
python -m pytest tests/utils/test_auth.py
python -m pytest tests/utils/test_qr_generator.py
```

### Integration Tests
```bash
# Test module interactions
python -m pytest tests/utils/test_integration.py
```

## Performance

### Logging Performance
- Structured JSON logging adds ~5-10% overhead
- Log rotation prevents disk space issues
- Async logging available for high-throughput scenarios

### Authentication Performance
- Token hashing uses PBKDF2 (100,000 iterations)
- In-memory caching for active sessions
- Rate limiting prevents abuse

### QR Generation Performance
- qrencode (C) faster than Python library
- Automatic fallback ensures reliability
- Caching prevents regeneration

## Future Enhancements

### Planned Features
- [ ] Async logging for better performance
- [ ] Database-backed authentication
- [ ] QR code caching system
- [ ] Metrics export (Prometheus)
- [ ] Log streaming (syslog, journald)
- [ ] Multi-factor authentication
- [ ] Session management
- [ ] API key permissions system

### Contributing
1. Follow existing code patterns
2. Add comprehensive logging
3. Include error handling
4. Write unit tests
5. Update documentation
