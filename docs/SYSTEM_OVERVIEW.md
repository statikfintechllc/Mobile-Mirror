# System Overview — Mobile Developer

## Purpose

**Mobile Developer** is a unified, zero-cloud remote development environment designed to let you code, build, and operate on your own hardware — from any device, anywhere — with maximum security and minimal setup pain. It’s built for hands-on creators, hackers, and devops who want to “just code” from their phone, tablet, or laptop, whether they’re at home, at work, or out in the world.

---

## Key Features

- **True Mobile Coding**: Write, run, debug, and manage your systems from your phone, tablet, or any browser—your code always runs on your own box.
- **No Cloud Dependency**: No public IP, no VPS, no third-party remote servers or SaaS lock-in.
- **Single QR Scan Onboarding**: After install, scan the terminal QR with your phone to open your code-server session instantly.
- **Self-Healing HTTPS**: All browser connections are over HTTPS (self-signed cert auto-generated), ensuring browser feature support and privacy.
- **Full System Control**: TUI (Text User Interface) menu lets you start, stop, or check logs for the full stack, without ever touching a terminal prompt.

---

## Core Stack and Design

### 1. **Tailscale — Secure Mesh Network**

- **Private global network**: Every device gets a stable 100.x.x.x WireGuard IP, routed privately and securely.
- **No Port Forwarding**: Works across firewalls, NAT, or public WiFi with no need to expose ports to the Internet.
- **Zero Trust**: Only devices authenticated with your Tailscale account can see or connect to each other.
- **All traffic is end-to-end encrypted** by WireGuard, so you’re secure even over LTE or public hotspots.

### 2. **code-server — Cloud VSCode, On Your Metal**

- **Full VSCode experience**: Runs in your browser, on your own hardware.
- **Persistent**: Your projects, files, and extensions are all local.
- **Mobile ready**: Use touch, copy/paste, and keyboard features from phone or tablet browsers.
- **HTTPS by default**: Browser sees a secure context, so all VSCode features are available.

### 3. **Automation Scripts**

- **Start/Stop Scripts**: One-click launch or kill for the entire remote dev stack. 
    - `start_all.sh` — launches Tailscale, ensures connection, spins up code-server with HTTPS, and prints a QR code for mobile access.
    - `stop_all.sh` — kills code-server processes on the specified port, shuts down Tailscale, and cleans up network state.
- **TUI Control Panel**: Optional script with a button-based CLI menu, letting you Start/Stop/View Logs from a simple graphical menu (no bash knowledge required).

### 4. **Desktop Integration**

- **App Launcher Icon**: Installs a `.desktop` file, so users can start the Mobile Developer TUI from their applications dash/panel just like any other app.
- **Pin and Forget**: Once installed, you can run/start/stop everything with a click, no terminal required.

---

## Workflow

1. **Install with one command.**
2. **Start**: Click the Mobile Developer icon or run the TUI script.
3. **Scan**: Use your phone camera/QR app to scan the QR code in the terminal.
4. **Code**: Browser opens to your secure code-server session; log in with your password and code as if you’re at your desk.
5. **Stop**: When done, use the TUI or launcher to shut down all services and tunnels instantly.

---

## Security Model

- **Zero Open Ports**: Nothing is accessible from the public internet.
- **Encrypted at Every Layer**: WireGuard VPN via Tailscale, plus HTTPS on the web UI, even over mobile.
- **No Vendor Lock**: All compute stays local, all configs are editable, and you can hard-reset the stack at any time.
- **Per-Device Authorization**: Only your devices, with your Tailscale credentials, can access the network.

---

## Use Cases

- **On-the-go development:** Fix bugs, ship code, or deploy updates from your phone—no laptop or special hardware needed.
- **Home lab/AI server management:** Check logs, reboot agents, or monitor status while you’re out.
- **Privacy-focused mobile dev:** Work remotely, even over untrusted networks, with no third-party risk.

---

## Technical Limitations

- **Self-signed certificate**: The HTTPS connection uses a self-generated cert; you’ll need to accept the warning in your browser once.
- **Requires Linux desktop/WSL**: Targeted for Ubuntu/Debian (but works on Arch and others with minimal tweaks).
- **GUI is terminal-based**: TUI for ease of use, not a full graphical app (keeps it cross-platform and minimal).

---

## Extending/Customizing

- **Add webhooks** for auto-start/stop via API or Shortcuts.
- **Integrate with system notifications** for remote job completion or alerts.
- **Swap code-server for other web tools** (Jupyter, RStudio, custom dashboards) — scripts are modular.
- **Custom icons, branding, and About Us content** for organizational rollout.

---

## In Summary

**Mobile Developer** is the fastest, safest, and simplest way to turn any Linux machine into a mobile-accessible dev powerhouse, letting you work from anywhere as if you never left home.

---

*For full folder layout and script details, see [STRUCTURE.md](./STRUCTURE.md).*
