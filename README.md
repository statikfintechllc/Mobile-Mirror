<link rel="stylesheet" type="text/css" href="docs/custom.css">
<div align="center">
  <a
href="https://github.com/statikfintechllc/Mobile-Developer/blob/master/LICENSE">
    <img src="https://img.shields.io/badge/Mobile-black?style=for-the-badge&logo=dragon&logoColor=gold" alt="Fair Use License"/>
  </a>
  <a href="https://github.com/statikfintechllc/Mobile-Developer/blob/master/LICENSE">
    <img src="https://img.shields.io/badge/Developer%20v.1.0.1-darkred?style=for-the-badge&logo=dragon&logoColor=gold" alt="GremlinGPT License"/>
  </a>
</div>

<div align="center">
  <a
href="https://github.com/statikfintechllc/AscendAI/blob/master/About Us/WHY_GREMLINGPT.md">
    <img src="https://img.shields.io/badge/Why-black?style=for-the-badge&logo=dragon&logoColor=gold" alt="Why"/>
  </a>
  <a href="https://github.com/statikfintechllc/AscendAI/blob/master/About Us/WHY_GREMLINGPT.md">
    <img src="https://img.shields.io/badge/GremlinGPT-darkred?style=for-the-badge&logo=dragon&logoColor=gold" alt="GremlinGPT"/>
  </a>
</div>

  <div align="center">
  <a href="https://ko-fi.com/statikfintech_llc">
    <img src="https://img.shields.io/badge/Support-black?style=for-the-badge&logo=dragon&logoColor=gold" alt="Support"/>
  </a>
  <a href="https://patreon.com/StatikFinTech_LLC?utm_medium=unknown&utm_source=join_link&utm_campaign=creatorshare_creator&utm_content=copyLink">
    <img src="https://img.shields.io/badge/SFTi-darkred?style=for-the-badge&logo=dragon&logoColor=gold" alt="SFTi"/>
  </a>

# Mobile Development. Instant. Secure. Anywhere.

</div>

> Remote code, build, and ops on your home computer — from your phone — with zero cloud or port-forwarding.

---

## 🚀 What is this?

**Mobile Developer** lets you:
- Write code, run terminals, and manage servers **from your phone** or tablet
- All compute runs securely on your own hardware — not in the cloud
- No public IP, no port forwarding, no Docker required

Powered by:
- [Tailscale](https://tailscale.com/) – WireGuard mesh VPN
- [code-server](https://github.com/coder/code-server) – VSCode in your browser

Plus:
- 🛠️ Robust bash automation
- 🔒 **Private mesh**: Only your devices can connect
- ⚡ **Mobile-optimized**: Scan a QR, code in seconds
- 🏠 **Home or remote**: Works over LTE, public WiFi, or anywhere

---

## 📦 Features

- ✅ App Icon and Naming for Easy Lauch after clone and install
- ✅ One-command start with secure HTTPS and self-signed certs
- ✅ QR code terminal output for mobile login
- ✅ Clean shutdown script: kills all tunnels and services
- ✅ No open ports or public exposure
- ✅ Desktop launcher: Start/Stop/Logs — no terminal required

---

## 🛠️ Setup

### Requirements

- Linux (Ubuntu 20.04+, Debian, Arch, Pop!\_OS tested)
- [Tailscale account (free)](https://tailscale.com/)
- `conda`, `kitty`, `git`, `curl`, `qrencode`, `whiptail` — auto-installed if missing
- `code-server` — auto-installed if missing

---

### 📥 Clone and Install

```bash
git clone https://github.com/youruser/mobile-developer.git
cd mobile-developer/env
chmod +x install.sh
./install.sh
```

# 📂 Usage

After install you can:

```bash
cd ../scripts
# Below is completed on my system for you but if it says permission denied, This is there.
chmod +x start_all.sh stop_all.sh
./start_all.sh
```

Then:

- Scan the QR code from your terminal  
- Open the HTTPS link on your mobile browser (accept the self-signed cert)  
- Log in using the code-server password from:

```bash
# Current password is: SFTi
~/.config/code-server/config.yaml
```

To stop:

```bash
./stop_all.sh
```

---

**If you are allergic to bash. No Worries. Its an App!!**

### 🖥️ Desktop Launcher

After install, you can:

- Look for **Mobile Developer v1.0.1** in your Linux App Launcher  
- Use the GUI panel for:  
  - ✅ Start  
  - ✅ Stop
  - ✅ Stop  

> No terminal required.

---

# 📖 Documentation

- [System Overview](https://github.com/statikfintechllc/Mobile-Developer/blob/master/docs/SYSTEM_OVERVIEW.md)
- [Directory Structure](https://github.com/statikfintechllc/Mobile-Developer/blob/master/docs/STRUCTURE.md)
- [About Us](https://github.com/statikfintechllc/Mobile-Developer/blob/master/About%20Us/)

---

# 🔐 Security

- End-to-end encrypted by WireGuard/Tailscale  
- No cloud relay; only your devices can connect  
- `code-server` runs on HTTPS with a local self-signed cert  
- Absolutely **no** public-facing ports

---

# 🙌 Credits

Built by **Statik DK Smoke** + **GremlinGPT Core**  
Open source. Contributions, forks, and feedback welcome.

> *System #3 in 3 weeks and 6 days, 1 Massive Proto-Type AGI, 1 3 part functioning AI ChatBot recieving persistence and 2 Brains, and now the solution to me not being able to Debug, As I'm never home.*
- StatikFinTech, LLC

---

## Support Options

| Method        | Handle / Link |
|---------------|---------------|
| **Patreon**   | [StatikFinTech, LLC](https://patreon.com/StatikFinTech_LLC?utm_medium=unknown&utm_source=join_link&utm_campaign=creatorshare_creator&utm_content=copyLink) |
| **Ko-Fi**     | [statikfintech_llc](https://ko-fi.com/statikfintech_llc) |
| **CashApp**   | [$statikmoney8](https://cash.app/$statikmoney8) |
| **PayPal**    | [paypal.me/statikmoney8](https://paypal.me/statikmoney8) |
| **Bitcoin**   | `bc1qarsr966ulmcs3mlcvae7p63v4j2y2vqrw74jl8` |
| **Ethereum**  | `0xC2db50A0fc6c95f36Af7171D8C41F6998184103F` |
| **Chime**     | `$StatikSmokTM` |

**Want equity, private access, or to sponsor hardware directly? Reach Out to:**
- **Email:** [ascend.gremlin@gmail.com](mailto:ascend.gremlin@gmail.com) | [ascend.help@gmail.com](mailto:ascend.help@gmail.com)
- **Text Us:** [+1 (785) 443-6288](sms:+17854436288)  
- **DM:**  
  - a) [LinkedIn: StatikFinTech, LLC](https://www.linkedin.com/in/statikfintech-llc-780804368/)
  - b) [X: @GremlinsForge](https://twitter.com/GremlinsForge)  

**See Our [Open Funding Proposal](https://github.com/statikfintechllc/Mobile-Developer/blob/master/docs/OPEN_FUNDING_PROPOSAL.md)**
