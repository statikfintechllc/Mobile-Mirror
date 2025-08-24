# Troubleshooting Guide

Common issues and solutions for Statik-Server.

## Server Won't Start

### Check if ports are in use
```bash
# Check for processes using required ports
netstat -tlnp | grep -E ':(8080|8443|50443)'

# Kill processes if needed
sudo kill -9 $(lsof -ti:8080)
```

### Verify installation
```bash
# Check if VS Code CLI exists
ls -la ~/statik-server/lib/code

# Re-run installer if missing
./install.sh
```

### Check logs
```bash
statik-cli logs
```

## VS Code Issues

### Local VS Code Won't Open
1. **Check binary exists:**
   ```bash
   ls -la ~/statik-server/lib/code
   ./lib/code --version
   ```

2. **Verify permissions:**
   ```bash
   chmod +x ~/statik-server/lib/code
   ```

3. **Try direct path:**
   ```bash
   statik-cli code /home/username
   ```

### Web VS Code Not Loading
1. **Check server status:**
   ```bash
   statik-cli status
   ```

2. **Verify port 8080:**
   ```bash
   curl http://localhost:8080
   ```

3. **Check firewall:**
   ```bash
   sudo ufw status
   sudo ufw allow 8080
   ```

## Mesh VPN Issues

### Can't Generate Connection Key
1. **Check Headscale status:**
   ```bash
   statik-cli mesh status
   ```

2. **Restart server:**
   ```bash
   statik-cli restart
   ```

3. **Check Headscale binary:**
   ```bash
   ls -la ~/statik-server/lib/headscale
   ```

### Remote Device Can't Connect
1. **Verify server URL:**
   ```bash
   statik-cli mesh info
   ```

2. **Check firewall ports:**
   ```bash
   # Open mesh VPN port
   sudo ufw allow 50443
   ```

3. **Regenerate key:**
   ```bash
   statik-cli mesh key
   ```

## GitHub Copilot Issues

### Copilot Not Working
1. **Set/check GitHub token:**
   ```bash
   statik-cli config token
   statik-cli config show
   ```

2. **Verify token has Copilot access:**
   - Go to GitHub Settings > Copilot
   - Ensure subscription is active

3. **Restart VS Code:**
   - Close and reopen VS Code
   - Sign in to GitHub again

## Permission Issues

### SSL Certificate Errors
```bash
# Regenerate certificates
rm -rf ~/.statik-server/keys/*
statik-cli restart
```

### File Permission Errors
```bash
# Fix permissions
chmod -R 600 ~/.statik-server/keys/
chmod +x ~/statik-server/lib/*
```

## GUI Issues

### GUI Won't Launch
1. **Check if installed:**
   ```bash
   ls -la ~/.local/share/applications/statik_cli.sh
   ```

2. **Reinstall GUI:**
   ```bash
   statik-cli install
   ```

3. **Try direct launch:**
   ```bash
   bash ~/.local/share/applications/statik_cli.sh
   ```

## Performance Issues

### High CPU Usage
1. **Check processes:**
   ```bash
   ps aux | grep -E "(code|headscale|socat)"
   ```

2. **Monitor resources:**
   ```bash
   statik-cli status
   htop
   ```

3. **Restart if needed:**
   ```bash
   statik-cli restart
   ```

### Slow Web VS Code
1. **Use local VS Code instead:**
   ```bash
   statik-cli code
   ```

2. **Check network latency:**
   ```bash
   ping localhost
   ```

## Network Issues

### Can't Access from Network
1. **Check firewall:**
   ```bash
   sudo ufw status
   sudo ufw allow 8080
   sudo ufw allow 8443
   ```

2. **Verify server binding:**
   ```bash
   netstat -tlnp | grep :8080
   ```

3. **Check network interface:**
   ```bash
   ip addr show
   ```

### Mobile Access Not Working
1. **Verify QR code URL:**
   ```bash
   statik-cli status
   ```

2. **Check mobile device is on same network:**
   ```bash
   ping [mobile-device-ip]
   ```

## Database Issues

### Mesh Database Corrupt
```bash
# Reset mesh database
statik-cli stop
rm -f ~/.statik-server/data/headscale.db
statik-cli start
```

### Configuration Reset
```bash
# Reset all configuration
statik-cli config reset
# Re-configure as needed
statik-cli config token
```

## Log Analysis

### View detailed logs
```bash
# Follow live logs
statik-cli logs -f

# View more history
statik-cli logs --tail 200

# Check system logs
journalctl -u statik-server --since "1 hour ago"
```

### Common log messages
- `Failed to start server` - Port already in use
- `Certificate not found` - Run `./install.sh` to regenerate
- `Permission denied` - Check file permissions
- `Connection refused` - Service not running

## Getting Help

### Collect system information
```bash
# System info
uname -a
cat /etc/os-release

# Statik-Server info
statik-cli status
statik-cli --version

# Process info
ps aux | grep -E "(statik|code|headscale)"
```

### Submit issue
1. **Collect logs:**
   ```bash
   statik-cli logs > statik-logs.txt
   ```

2. **Include system info:**
   - Operating system
   - Statik-Server version
   - Error messages
   - Steps to reproduce

3. **Submit to GitHub:**
   https://github.com/statikfintechllc/statik-server/issues

## Reset Everything

### Complete reset
```bash
# Stop server
statik-cli stop

# Remove all data
rm -rf ~/.statik-server

# Uninstall
statik-cli uninstall

# Re-install
./install.sh
```

This should resolve most issues by starting fresh.
