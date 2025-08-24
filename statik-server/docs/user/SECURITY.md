# 🔐 Security & Certificates Guide

Understanding Statik-Server's security model and certificate management.

## 🛡️ Security Overview

Statik-Server implements a comprehensive security model:
- **Self-Signed Certificates**: Automatic HTTPS encryption
- **Mesh VPN**: WireGuard-based secure networking
- **Zero Trust**: No external dependencies required
- **Local Control**: You control all security components

## 🔑 Certificate Management

### Automatic Certificate Generation
Statik-Server automatically generates all required certificates during installation:

```bash
~/.statik-server/keys/
├── server.crt          # HTTPS certificate
├── server.key          # HTTPS private key
├── noise.key           # Mesh VPN noise key
├── derp.key            # DERP server key
├── preauth.key         # Mesh pre-authentication key
└── auto-connect.key    # Auto-connect mesh key
```

### Certificate Details
- **Algorithm**: RSA 4096-bit
- **Validity**: 365 days
- **Subject**: CN=statik.local
- **Usage**: Web server and mesh VPN authentication

### Manual Certificate Regeneration
```bash
# Stop server
statik-cli stop

# Remove existing certificates
rm ~/.statik-server/keys/server.{crt,key}

# Restart (will regenerate certificates)
statik-cli start
```

## 🌐 HTTPS Configuration

### Automatic HTTPS Setup
Statik-Server automatically configures HTTPS with:
- **Port 8080**: HTTP (VS Code server)
- **Port 8443**: HTTPS (TLS proxy)
- **Custom Domain**: `[hostname].statik.local:8443`

### Browser Security Warnings
Since certificates are self-signed, browsers will show security warnings:

#### Chrome/Edge
1. Click "Advanced"
2. Click "Proceed to [hostname].statik.local (unsafe)"

#### Firefox
1. Click "Advanced"
2. Click "Accept the Risk and Continue"

#### Safari
1. Click "Show Details"
2. Click "visit this website"
3. Click "Visit Website"

### Adding Certificate to Trust Store

#### Linux
```bash
# Copy certificate to system trust store
sudo cp ~/.statik-server/keys/server.crt /usr/local/share/ca-certificates/statik-server.crt
sudo update-ca-certificates
```

#### macOS
```bash
# Add to keychain
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ~/.statik-server/keys/server.crt
```

## 🔐 Mesh VPN Security

### WireGuard Protocol
Statik-Server uses WireGuard for mesh networking:
- **Encryption**: ChaCha20Poly1305 authenticated encryption
- **Key Exchange**: Curve25519 elliptic curve
- **Transport**: UDP with NAT traversal
- **Authentication**: Pre-shared keys

### Key Management
```bash
# Generate new mesh connection key
statik-cli mesh key

# View mesh status
statik-cli mesh status

# List connected devices
statik-cli mesh devices
```

### Mesh Security Features
- **Perfect Forward Secrecy**: Keys rotate automatically
- **Device Authentication**: Each device has unique keys
- **Network Isolation**: Mesh traffic is isolated from internet
- **Zero Configuration**: Automatic key exchange and setup

## 🔒 Access Control

### Default Security Model
- **Local Access**: No authentication required for localhost
- **Network Access**: No authentication (trusted network assumption)
- **Mesh Access**: Authenticated via pre-shared keys
- **HTTPS**: TLS encryption for all web traffic

### Hardening Options

#### Enable VS Code Authentication
```bash
# Edit startup script to add authentication
# Add --auth flag to VS Code startup command
```

#### Firewall Configuration
```bash
# Restrict access to specific networks
sudo ufw allow from 192.168.1.0/24 to any port 8080
sudo ufw allow from 192.168.1.0/24 to any port 8443
```

#### Mesh Network Isolation
```bash
# Configure mesh to only allow specific services
# Edit headscale configuration for ACL rules
```

## 🛡️ Security Best Practices

### Server Security
1. **Keep Updated**: Regularly update Statik-Server
2. **Monitor Access**: Check logs for unauthorized access
3. **Network Segmentation**: Use VLANs or firewall rules
4. **Regular Backups**: Backup configuration and keys

### Development Security
1. **Code Review**: Review AI-generated code for security issues
2. **Dependency Scanning**: Check dependencies for vulnerabilities
3. **Secrets Management**: Don't commit sensitive data
4. **Environment Isolation**: Use different environments for dev/prod

### Network Security
1. **VPN Usage**: Use mesh VPN for remote access
2. **Firewall Rules**: Restrict unnecessary ports
3. **Monitor Traffic**: Log and monitor network access
4. **Regular Audits**: Review security configuration

## 🚨 Security Monitoring

### Log Analysis
```bash
# View access logs
statik-cli logs

# Monitor mesh connections
statik-cli mesh devices

# Check system status
statik-cli status
```

### Security Events to Monitor
- **Failed Connections**: Repeated connection attempts
- **Unusual Traffic**: Unexpected network patterns
- **Certificate Errors**: TLS handshake failures
- **Mesh Anomalies**: Unauthorized device connections

### Alerting Setup
```bash
# Set up log monitoring (example with journalctl)
journalctl -u statik-server -f | grep "SECURITY"

# Monitor failed authentication attempts
grep "authentication failed" ~/.statik-server/logs/statik-server.log
```

## 🔧 Troubleshooting Security Issues

### Certificate Problems
```bash
# Check certificate validity
openssl x509 -in ~/.statik-server/keys/server.crt -text -noout

# Verify certificate and key match
openssl x509 -noout -modulus -in ~/.statik-server/keys/server.crt | openssl md5
openssl rsa -noout -modulus -in ~/.statik-server/keys/server.key | openssl md5
```

### Mesh VPN Issues
```bash
# Check mesh connectivity
statik-cli mesh status

# Regenerate mesh keys
statik-cli mesh key

# Restart mesh service
statik-cli restart
```

### HTTPS Connection Problems
1. **Check Certificate**: Verify certificate is not expired
2. **Browser Cache**: Clear browser cache and certificates
3. **Firewall**: Ensure ports 8080 and 8443 are open
4. **DNS**: Verify domain resolution

## 📋 Security Checklist

### Initial Setup
- [ ] Certificates generated automatically
- [ ] HTTPS enabled and working
- [ ] Mesh VPN configured
- [ ] Firewall rules in place
- [ ] Access controls configured

### Regular Maintenance
- [ ] Monitor access logs
- [ ] Update Statik-Server regularly
- [ ] Review mesh device list
- [ ] Check certificate expiration
- [ ] Audit security configuration

### Incident Response
- [ ] Document security procedures
- [ ] Test backup/recovery processes
- [ ] Plan for certificate rotation
- [ ] Monitor for security updates
- [ ] Train users on security practices

---

## 🔗 Related Documentation

- [Mesh VPN Overview](../mesh/MESH_OVERVIEW.md) - VPN setup and management
- [Troubleshooting](../TROUBLESHOOTING.md) - Common security issues
- [Installation Guide](../INSTALL.md) - Secure installation practices
