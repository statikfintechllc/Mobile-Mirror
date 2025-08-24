# CLI Reference

Complete reference for all Statik-Server CLI commands and options.

## Core Commands

### `statik-cli start`
Start the Statik-Server with all components.

```bash
statik-cli start [--daemon]
```

**Options:**
- `--daemon` - Run in background mode

**What it does:**
- Starts VS Code server on port 8080
- Initializes mesh VPN (Headscale) on port 50443
- Sets up HTTPS proxy on port 8443
- Opens required firewall ports
- Generates QR codes for mobile access

### `statik-cli stop`
Stop all Statik-Server processes.

```bash
statik-cli stop
```

**What it does:**
- Stops VS Code server
- Terminates mesh VPN processes
- Stops HTTPS proxy
- Cleans up PID files

### `statik-cli restart`
Restart the server (stop + start).

```bash
statik-cli restart
```

### `statik-cli status`
Show detailed server and system status.

```bash
statik-cli status
```

**Output includes:**
- Server running status
- System uptime and load
- Memory usage
- Port status (8080, 8081, 50443)
- Process information

## Development Commands

### `statik-cli code`
Open VS Code locally using the desktop application.

```bash
statik-cli code [path]
```

**Interactive Mode (no path):**
```bash
statik-cli code
```
Shows menu with options:
1. Current directory
2. Home directory
3. Statik-Server directory
4. Custom path

**Direct Mode (with path):**
```bash
statik-cli code ~/my-project
statik-cli code /path/to/workspace
statik-cli code .
```

### `statik-cli open`
Open the web VS Code interface in your default browser.

```bash
statik-cli open
```

Opens: `http://localhost:8080`

### `statik-cli build`
Build or update the server components.

```bash
statik-cli build
```

**What it does:**
- Updates VS Code CLI
- Rebuilds mesh VPN components
- Updates dependencies

## Configuration

### `statik-cli config`
Manage server configuration.

```bash
statik-cli config [action]
```

**Actions:**
- `token` - Set GitHub token for Copilot access
- `show` - Display current configuration
- `reset` - Reset all configuration

**Examples:**
```bash
statik-cli config token    # Set GitHub token
statik-cli config show     # View current config
statik-cli config reset    # Reset configuration
```

## Mesh VPN Management

### `statik-cli mesh`
Manage mesh VPN and connected devices.

```bash
statik-cli mesh [command]
```

**Commands:**
- `status` - Show mesh status and connection info
- `key` - Generate new connection key
- `connect` - Show connection instructions
- `devices` - List connected devices
- `info` - Show detailed mesh configuration

**Examples:**
```bash
statik-cli mesh status     # Check mesh status
statik-cli mesh key        # Generate auth key for new device
statik-cli mesh devices    # List all connected devices
```

## Logging and Monitoring

### `statik-cli logs`
View server logs.

```bash
statik-cli logs [options]
```

**Options:**
- `--tail N` - Show last N lines (default: 40)
- `--follow` or `-f` - Follow logs in real-time

**Examples:**
```bash
statik-cli logs              # Show last 40 lines
statik-cli logs --tail 100   # Show last 100 lines
statik-cli logs -f           # Follow logs in real-time
```

## GUI and Desktop Integration

### `statik-cli gui`
Launch the interactive GUI interface.

```bash
statik-cli gui
```

Opens a full-featured GUI with:
- Start/stop controls
- System monitoring
- Log viewing
- Configuration management
- VS Code local/web access

### `statik-cli install`
Install desktop application and system integration.

```bash
statik-cli install
```

**What it installs:**
- Desktop application entry
- System icons
- GUI launcher script
- CLI wrapper scripts

### `statik-cli uninstall`
Remove desktop application and system integration.

```bash
statik-cli uninstall
```

## Git Integration

### `statik-cli commit`
Commit changes with a message.

```bash
statik-cli commit -m "commit message"
```

### `statik-cli push`
Push commits to remote repository.

```bash
statik-cli push
```

### `statik-cli sync`
Add all changes, commit, and push in one command.

```bash
statik-cli sync -m "commit message"
```

## Global Options

All commands support these global options:

- `-h, --help` - Show help message
- `-v, --verbose` - Enable verbose output
- `-q, --quiet` - Suppress output

**Examples:**
```bash
statik-cli start --verbose    # Start with detailed output
statik-cli status --quiet     # Check status silently
statik-cli --help             # Show general help
```

## Exit Codes

- `0` - Success
- `1` - General error
- `2` - Syntax error
- `130` - Interrupted by user (Ctrl+C)

## Environment Variables

- `STATIK_PORT` - Override default port (default: 8080)
- `STATIK_HTTPS_PORT` - Override HTTPS port (default: 8443)
- `STATIK_DOMAIN` - Override domain (default: hostname.statik.local)
- `GITHUB_TOKEN` - GitHub token for Copilot (also configurable via `config token`)

## Configuration Files

- `~/.statik-server/config/` - Main configuration directory
- `~/.statik-server/keys/` - SSL certificates and keys
- `~/.statik-server/logs/` - Log files
- `~/.statik-server/data/` - Database and data files
