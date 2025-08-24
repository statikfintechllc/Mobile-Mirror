<div align="center">
  <img  
	  src="https://raw.githubusercontent.com/KDK-Grim/WorkFlowRepo-Mirror/master/docs/ticker-bot/ticker.gif" 
  alt="Repo Ticker Stats" 
  style="height:33px;" />
</div>

<div align="center"> 
   <a href="https://github.com/statikfintechllc/WorkFlowRepo.git">
  <img src="https://img.shields.io/badge/Click%20to%20Install%20Single-Repo%20Traffic%20Workflows-darkred?labelColor=black" alt="WorkFlowRepo"/>
  </a>
   <a href="https://github.com/KDK-Grim/WorkFlowRepo-Mirror">
  <img src="https://img.shields.io/badge/Click%20to%20Install-Advance%20Mirror%20Workflow-darkred?labelColor=black" alt="WorkFlowRepo Mirror"/>
  </a>
</div>

<div align="center"> 
  <img  
	  src="https://img.shields.io/github/stars/statikfintechllc/statik-server?style=social" alt="Stars"/>
  <img  
	  src="https://img.shields.io/github/forks/statikfintechllc/statik-server?style=social" alt="Forks"/>
  <img  
	  src="https://img.shields.io/github/last-commit/statikfintechllc/statik-server?style=social" alt="Last Commit"/>
</div>

<div align="center">
  <img src="https://img.shields.io/badge/Status-v1.0.0-black?style=for-the-badge&labelColor=black&color=darkred&logo=ghost&logoColor=white" alt="Status">
  <img src="https://img.shields.io/badge/VS%20Code-1.102.0+-black?style=for-the-badge&labelColor=black&color=darkred&logo=visualstudiocode&logoColor=white" alt="VS Code"/>
  <img src="https://img.shields.io/badge/Copilot-Chat%20Enabled-black?style=for-the-badge&labelColor=black&color=darkgreen&logo=githubcopilot&logoColor=white" alt="Copilot Chat Enabled"/>
  <img src="https://img.shields.io/badge/Mesh%20VPN-Tailscale-black?style=for-the-badge&labelColor=black&color=darkred&logo=tailscale&logoColor=white" alt="Mesh VPN">
  <img src="https://img.shields.io/badge/MIT%20Open-Usage-black?style=for-the-badge&labelColor=black&color=darkred&logo=ghost&logoColor=white" alt="License">
</div>

<div align="center">
  <a href="https://ko-fi.com/statikfintech_llc">
  <img  
	  src="https://img.shields.io/badge/Sponsor%20SFTi%20on%20KoFi-darkred?style=for-the-badge&logo=dragon&logoColor=gold" alt="Support"/>
  </a>
  <a href="https://patreon.com/StatikFinTech_LLC?utm_medium=unknown&utm_source=join_link&utm_campaign=creatorshare_creator&utm_content=copyLink">
  <img  
	  src="https://img.shields.io/badge/Sponsor%20SFTi%20on%20Patreon-black?style=for-the-badge&logo=dragon&logoColor=gold" alt="SFTi"/>
  </a>
</div>
<div align="center"> 

[![Sponsor 💪 statikfintechllc](https://img.shields.io/badge/Sponsor%20SFTi%20on%20GitHub-darkred?logo=github&style=for-the-badge)](https://github.com/sponsors/statikfintechllc)

</div>

<div align="center">

# 🚀 Statik-Server
**Sovereign AI Development Environment with Mesh VPN**

Transform any machine into a powerful, globally accessible AI development environment with one command.

</div>

## 📑 Table of Contents

<details>
<summary><strong>🚀 Getting Started</strong></summary>

- [Quick Start](#-quick-start)
- [Launch Commands](#-launch-commands)
- [System Requirements](#-system-requirements)

</details>

<details>
<summary><strong>✨ Features & Architecture</strong></summary>

- [Core Features](#-features)
- [Architecture Overview](#-architecture-overview)
- [VS Code Integration](#-vs-code-integration)
- [Mesh VPN Details](#-mesh-vpn-architecture)

</details>

<details>
<summary><strong>🔧 Usage & Access</strong></summary>

- [Access Methods](#-access-your-environment)
- [Local Development](#-ai-powered-development)
- [Mesh VPN Setup](#-mesh-vpn-setup)
- [CLI Commands](#-cli-commands)

</details>

<details>
<summary><strong>📚 Documentation</strong></summary>

- [User Guide](docs/user/)
- [Development Guide](docs/development/)
- [Mesh VPN Guide](docs/mesh/)
- [API Reference](docs/api/)

</details>

<details>
<summary><strong>🎨 Customization</strong></summary>

- [Choose Your Emblem](#-choose-your-emblem)
- [Configuration](docs/user/configuration.md)
- [Extensions](docs/development/extensions.md)

</details>

## ✨ Features

- **🤖 GitHub Copilot Chat** - Full AI pair programming with official Microsoft integration
- **💻 Local VS Code** - Open desktop VS Code with `statik-cli code`
- **🌐 Web VS Code** - Browser-based development environment
- **🌐 Mesh VPN** - Uses existing Tailscale connection for global access
- **📡 Global Access** - HTTPS with auto-generated certificates
- **🔐 Zero Config** - Auto-generated keys & persistent authentication
- **📱 Mobile Ready** - QR codes for instant access
- **⚡ VS Code 1.102.0+** - Official Microsoft server
- **🎯 One Command** - Complete environment in minutes
- **🔄 Git Integration** - Built-in git workflow commands

## 🚀 Quick Start

```bash
curl -sSL https://raw.githubusercontent.com/statikfintechllc/statik-server/master/scripts/install.sh | bash
```

That's it! The installer handles everything:
- Detects your platform (Linux/macOS)
- Installs all dependencies
- Downloads VS Code CLI
- Builds mesh VPN
- Generates certificates
- Sets up GitHub Copilot
- Creates desktop integration

## ⚡ Launch Commands

After installation:

```bash
# Start the server
statik

# Or use the CLI
statik-cli start

# Check status
statik-cli status

# Open VS Code locally
statik-cli code

# Open in browser
statik-cli open
```

## 🏗️ Architecture Overview

Statik-Server combines the best of several technologies to create a sovereign AI development environment:

### Core Components
- **VS Code Server**: Official Microsoft VS Code server (v1.102.0+) with full extension support
- **GitHub Copilot**: Native Microsoft integration for AI pair programming
- **Tailscale**: Mesh VPN for secure global access to your development environment
- **HTTPS Proxy**: Auto-generated TLS certificates for secure access

### Mesh VPN Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Your Device   │    │ Statik-Server   │    │  Remote Device  │
│                 │    │                 │    │                 │
│ Tailscale Client├────┤ Tailscale Client├────┤ Tailscale Client│
│                 │    │ + VS Code       │    │                 │
│                 │    │ + Copilot       │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

**Why this works so well:**
- **Microsoft-friendly**: Uses official VS Code server and Copilot integration
- **Zero-setup mesh**: Leverages existing Tailscale infrastructure
- **Instant access**: Connect any device already in your Tailscale network
- **Secure by default**: WireGuard-based encryption with device authentication

## 📋 System Requirements

### Minimum Requirements
- **OS**: Linux (Ubuntu 20.04+, Debian 11+, CentOS 8+) or macOS 12+
- **RAM**: 2GB minimum, 4GB recommended
- **Storage**: 5GB free space
- **Network**: Internet connection for initial setup

### Dependencies (Auto-installed)
- Git, curl, wget, unzip
- Node.js 18+ and npm
- Go 1.21+ (for Tailscale compilation)
- OpenSSL for certificate generation
- UFW or iptables for firewall management

## 🎨 Choose Your Emblem

You can select your preferred Statik-Server emblem for desktop and mobile:

<div style="display: flex; gap: 32px; align-items: center;">
  <div style="text-align: center;">
    <img src="src/icon1.png" alt="Emblem 1" width="128" height="128" />
    <br />
    <a href="src/icon1.png">Download icon1.png</a>
    <br />
    <b>Emblem 1</b>
  </div>
  <div style="text-align: center;">
    <img src="src/icon2.png" alt="Emblem 2 (mobile)" width="128" height="128" />
    <br />
    <a href="src/icon2.png">Download icon2.png</a>
    <br />
    <b>Emblem 2 (mobile)</b>
  </div>
</div>

Mobile users: Emblem 2 is automatically resized to 512x512 for best experience.

---

<div align="center">
	
# AscendAI Traffic</h1>
 
 **The World's First RS-RACS**  
*Recursive, Self-Referential Autonomous Cognitive System*

</div> 
<div align="center">
  <a href="https://raw.githubusercontent.com/statikfintechllc/AscendAI/master/About US/">
  <img src="https://raw.githubusercontent.com/KDK-Grim/WorkFlowRepo-Mirror/master/docs/graph/traffic_graph.png" alt="Traffic Graph" />
  </a>
   <a href="https://github.com/statikfintechllc/WorkFlowRepo.git">
  <img src="https://img.shields.io/badge/Click%20to%20Install-Graph%20Workflow-darkred?labelColor=black" alt="Graph Workflow"/>
  </a>
</div>
  
<div align="center">
  <em>
Reset: After 7:00pm CST on First 2 Clones
  </em>
</div>

<div align="center">
  <a href="https://github.com/statikfintechllc/AscendAI/blob/master/GremlinGPT">
  <img src="https://img.shields.io/badge/v1.0.0-Statik--Server-darkred?labelColor=black" alt="Statik-Server v1.0.0"/>
  </a>
  <a href="https://github.com/statikfintechllc/AscendAI/blob/master/About Us/FOUNDER_LOG.md">
  <img src="https://img.shields.io/badge/Founder's%20Log-Manifesto-darkred?labelColor=black" alt="Founder's Log"/>
  </a>
  <a href="https://github.com/statikfintechllc">
  <img src="https://img.shields.io/badge/contributors-1-darkred?labelColor=black" alt="Contributors"/>
  </a>
  <a href="https://github.com/statikfintechllc/AscendAI/blob/master/About Us/FOUNDER_STATEMENT.md">
  <img src="https://img.shields.io/badge/Founder's%20Log-Statement-darkred?labelColor=black" alt="Founder's Statement"/>
  </a>
</div>

<div align="center">
  <a href="https://github.com/statikfintechllc/AscendAI/blob/master/GremlinGPT/docs/GREMLINGPT_AUTONOMY_REPORT.md">
  <img src="https://img.shields.io/badge/The%20Autonomous-black?style=for-the-badge&logo=dragon&logoColor=gold" alt="Autonomy Report"/>
  </a>
  <a href="https://github.com/statikfintechllc/AscendAI/blob/master/GremlinGPT/docs/GREMLINGPT_AUTONOMY_REPORT.md">
  <img src="https://img.shields.io/badge/Statik--Server%20v1.0.0-darkred?style=for-the-badge&logo=dragon&logoColor=gold" alt="Statik-Server"/>
  </a>
</div>

---

## 🌐 Access Your Environment

Once running, access your development environment via:

### 🖥️ Local Access
- **Web Interface**: http://localhost:8080
- **Local VS Code**: `statik-cli code`
- **HTTPS**: https://localhost:8443

### 🌍 Global Access (via Mesh VPN)
- Connect any device with Tailscale to your mesh network
- Access VS Code from anywhere in the world
- Secure WireGuard-based tunnel

### 📱 Mobile Access
- Scan QR codes displayed at startup
- Install Tailscale on mobile device
- Connect to your development environment

## 🌐 Mesh VPN Setup

### 1. Connect to Tailscale
Connect your Statik-Server to your existing Tailscale network:

```bash
# Install Tailscale (if not already installed)
curl -fsSL https://tailscale.com/install.sh | sh

# Connect to your tailnet
sudo tailscale up
```

### 2. Access from Any Device
Once connected to Tailscale, access your Statik-Server from any device in your tailnet:

```bash
# Get your Tailscale IP
tailscale ip

# Access VS Code via Tailscale
# https://[your-tailscale-ip]:8443
```

### 3. Add New Devices
Add new devices to your mesh via the Tailscale admin console:
- Visit https://login.tailscale.com/admin/machines
- Add new devices to your tailnet
- They'll automatically have access to your Statik-Server

## 🛠️ CLI Commands

The `statik-cli` provides complete control over your environment:

### Server Management
```bash
statik-cli start          # Start the server
statik-cli stop           # Stop the server  
statik-cli restart        # Restart the server
statik-cli status         # Show detailed status
statik-cli logs           # View server logs
```

### Development Tools
```bash
statik-cli code           # Open VS Code locally
statik-cli code ~/project # Open specific project
statik-cli open           # Open in browser
statik-cli gui            # Launch interactive GUI
```

### Mesh VPN Management
```bash
statik-cli mesh status    # Check Tailscale mesh status
statik-cli mesh info      # Detailed network information
tailscale status          # View all devices in mesh
tailscale ip              # Show your mesh IP address
```

### Configuration
```bash
statik-cli config token   # Set GitHub token
statik-cli build          # Build/update server
statik-cli install        # Install desktop app
```

### Git Integration
```bash
statik-cli commit -m "msg" # Git commit
statik-cli push            # Git push
statik-cli sync -m "msg"   # Add, commit, push
```

<div align="center">
  <a href="https://medium.com/@statikfintechllc">
    <img src="https://img.shields.io/badge/Statik--Server%20Guide-black?style=for-the-badge&logo=medium&logoColor=white" alt="Statik-Server Guide"/>
  </a>
  <a href="https://medium.com/@statikfintechllc">
    <img src="https://img.shields.io/badge/Mesh%20VPN%20Setup-black?style=for-the-badge&logo=medium&logoColor=white" alt="Mesh VPN Setup"/>
  </a>
  <a href="https://medium.com/@statikfintechllc">
    <img src="https://img.shields.io/badge/AI%20Development%20Environment-black?style=for-the-badge&logo=medium&logoColor=white" alt="AI Development Environment"/>
  </a>
  <a href="https://medium.com/@statikfintechllc">
    <img src="https://img.shields.io/badge/Sovereign%20Computing-black?style=for-the-badge&logo=medium&logoColor=white" alt="Sovereign Computing"/>
  </a>
  <a href="https://medium.com/@statikfintechllc">
    <img src="https://img.shields.io/badge/GitHub%20Copilot%20Integration-black?style=for-the-badge&logo=medium&logoColor=white" alt="GitHub Copilot Integration"/>
  </a>
  <a href="https://medium.com/@statikfintechllc">
    <img src="https://img.shields.io/badge/Mobile%20Development%20Setup-black?style=for-the-badge&logo=medium&logoColor=white" alt="Mobile Development Setup"/>
  </a>
</div>

<div align="center">
  <a href="https://zenodo.org/communities/statikfintechllc">
    <img src="https://img.shields.io/badge/Statik--Server%20Architecture-black?style=for-the-badge&logo=zenodo&logoColor=white" alt="Statik-Server Architecture"/>
  </a>
  <a href="https://zenodo.org/communities/statikfintechllc">
    <img src="https://img.shields.io/badge/Mesh%20VPN%20Protocol-black?style=for-the-badge&logo=zenodo&logoColor=white" alt="Mesh VPN Protocol"/>
  </a>
  <a href="https://zenodo.org/communities/statikfintechllc">
    <img src="https://img.shields.io/badge/Sovereign%20AI%20Development-black?style=for-the-badge&logo=zenodo&logoColor=white" alt="Sovereign AI Development"/>
  </a>
</div>
<div align="center">
  <a href="https://github.com/statikfintechllc">
  <img src="https://img.shields.io/badge/GitHub-black?style=for-the-badge&logo=github&logoColor=gold"/>
  <a href="https://github.com/statikfintechllc">
  <img src="https://img.shields.io/badge/SFTi%20Home-darkred?style=for-the-badge&logo=dragon&logoColor=gold"/>
  </a><br>
  <a href="https://github.com/statikfintechllc/GodCore.git">
  <img src="https://img.shields.io/badge/GodCore-black?style=for-the-badge&logo=dragon&logoColor=gold"/>
  <a href="https://github.com/statikfintechllc/GodCore.git">
  <img src="https://img.shields.io/badge/DualRouter-darkred?style=for-the-badge&logo=dragon&logoColor=gold"/>
  </a>
  <a href="https://github.com/statikfintechllc/Mobile-Developer.git">
  <img src="https://img.shields.io/badge/Mobile--Developer-black?style=for-the-badge&logo=dragon&logoColor=gold"/>
  <a href="https://github.com/statikfintechllc/Mobile-Developer.git">
  <img src="https://img.shields.io/badge/Mobile--Mirror-darkred?style=for-the-badge&logo=dragon&logoColor=gold"/>
  </a>
  <a href="https://github.com/statikfintechllc/AscendNet.git">
  <img src="https://img.shields.io/badge/AscendNet-black?style=for-the-badge&logo=dragon&logoColor=gold"/>
  <a href="https://github.com/statikfintechllc/AscendNet.git">
  <img src="https://img.shields.io/badge/Statik--Server-darkred?style=for-the-badge&logo=dragon&logoColor=gold"/>
  </a>
  <a href="https://github.com/statikfintechllc/WorkFlowRepo.git">
  <img src="https://img.shields.io/badge/WorkFlow-black?style=for-the-badge&logo=dragon&logoColor=gold"/>
  <a href="https://github.com/statikfintechllc/WorkFlowRepo.git">
  <img src="https://img.shields.io/badge/Repository-darkred?style=for-the-badge&logo=dragon&logoColor=gold"/>
  </a>
</div>

<div align="center">
  <a href="https://youtube.com/@gremlins_forge?si=9_OjKtlEPIErBrO2">
  <img src="https://img.shields.io/badge/YouTube-black?style=for-the-badge&logo=youtube&logoColor=gold"/>
  <a href="https://youtube.com/@gremlins_forge?si=9_OjKtlEPIErBrO2">
  <img src="https://img.shields.io/badge/Demos-darkred?style=for-the-badge&logo=dragon&logoColor=gold"/>
  </a>
</div>

<div align="center"> 
  <a href="mailto:ascend.gremlin@gmail.com">
  <img src="https://img.shields.io/badge/Ask-black?style=for-the-badge&logo=dragon&logoColor=gold"/>
  </a>
  <a href="mailto:ascend.gremlin@gmail.com">
  <img src="https://img.shields.io/badge/Gremlin-darkred?style=for-the-badge&logo=gmail&logoColor=gold"/>
  </a>
  <a href="mailto:ascend.help@gmail.com">
  <img src="https://img.shields.io/badge/Help-darkred?style=for-the-badge&logo=gmail&logoColor=gold"/>
  </a>
</div>

<div align="center"> 
  <a href="sms:+17854436288">
  <img src="https://img.shields.io/badge/Text%20Us-black?style=for-the-badge&logo=&logoColor=white"/>
  </a>
  <a href="sms:+17854436288">
  <img src="https://img.shields.io/badge/+1%20785%20443%206288-darkred?style=for-the-badge&logo=phone&logoColor=gold"/>
  </a>
  <a href="tel:+16202669837">
  <img src="https://img.shields.io/badge/Call%20Us-black?style=for-the-badge&logo=&logoColor=white"/>
  </a>
  <a href="tel:+16202669837">
  <img src="https://img.shields.io/badge/+1%20620%20266%209837-darkred?style=for-the-badge&logo=phone&logoColor=gold"/>
  </a>
</div>

---

**Ready to code from anywhere with AI assistance? Install now and start building the future!** 🚀
## 🔗 Repository

- **GitHub**: https://github.com/statikfintechllc/AscendNet
- **Issues**: https://github.com/statikfintechllc/AscendNet/issues
- **License**: MIT

---

**Ready to code from anywhere with AI assistance? Install now and start building the future!** 🚀
