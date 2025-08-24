# 📱 Mobile Access Guide

Access your Statik-Server development environment from any mobile device with full functionality.

## 🎯 Overview

Statik-Server provides a complete mobile development experience through:
- **Web VS Code**: Responsive browser-based IDE
- **QR Code Access**: Instant mobile connection
- **Touch Optimized**: Mobile-friendly interface
- **Mesh VPN**: Secure global access

## 📱 Quick Mobile Setup

### 1. Start Statik-Server
```bash
statik-cli start
```

### 2. Get Mobile Access
Two methods to access from mobile:

#### Method A: QR Code (Recommended)
1. QR code appears automatically on server startup
2. Scan with your mobile camera
3. Instantly access VS Code in your mobile browser

#### Method B: Direct URL
```
http://[your-ip]:8080
https://[your-domain]:8443
```

## 🌐 Web VS Code on Mobile

### Mobile Features
- **Full IDE**: Complete VS Code experience in mobile browser
- **GitHub Copilot**: AI assistance works on mobile
- **File Management**: Browse, edit, and create files
- **Terminal Access**: Command line interface
- **Extensions**: Web-compatible extensions available

### Mobile Optimizations
- **Touch Controls**: Optimized for finger navigation
- **Responsive Layout**: Adapts to different screen sizes
- **Mobile Keyboard**: Works with on-screen keyboards
- **Gesture Support**: Swipe and pinch gestures

### Supported Mobile Browsers
- ✅ **Safari** (iOS)
- ✅ **Chrome** (Android/iOS)
- ✅ **Firefox** (Android/iOS)
- ✅ **Edge** (Android/iOS)
- ✅ **Samsung Internet** (Android)

## 🔒 Secure Mobile Access

### Mesh VPN Setup for Mobile
Connect your mobile device to your development mesh:

#### iOS/iPadOS
1. Install Tailscale from App Store
2. Get connection key: `statik-cli mesh key`
3. Add network in Tailscale app using the key
4. Access VS Code via mesh IP

#### Android
1. Install Tailscale from Google Play
2. Get connection key: `statik-cli mesh key`
3. Add network in Tailscale app using the key
4. Access VS Code via mesh IP

### Benefits of Mesh Access
- **Global Access**: Connect from anywhere in the world
- **Secure**: Encrypted WireGuard tunnels
- **No Port Forwarding**: Works behind firewars and NAT
- **Multi-Device**: Connect multiple mobile devices

## 📝 Mobile Development Workflow

### Coding on Mobile
1. **Quick Edits**: Perfect for small changes and reviews
2. **Code Review**: Review pull requests and commits
3. **Documentation**: Write and update documentation
4. **Debugging**: Check logs and debug issues
5. **Git Operations**: Commit, push, and manage repositories

### Best Practices for Mobile Development
- **Use External Keyboard**: Bluetooth keyboard for extended coding
- **Split Screen**: Use mobile split-screen for reference materials
- **Voice Input**: Use voice-to-text for comments and documentation
- **Shortcuts**: Learn mobile VS Code keyboard shortcuts

## ⌨️ Mobile Keyboard Shortcuts

### iOS Safari
- **Copy**: Cmd+C
- **Paste**: Cmd+V
- **Undo**: Cmd+Z
- **Search**: Cmd+F
- **Save**: Cmd+S

### Android Chrome
- **Copy**: Ctrl+C
- **Paste**: Ctrl+V
- **Undo**: Ctrl+Z
- **Search**: Ctrl+F
- **Save**: Ctrl+S

### VS Code Mobile Shortcuts
- **Command Palette**: Ctrl+Shift+P (or Cmd+Shift+P)
- **Quick Open**: Ctrl+P (or Cmd+P)
- **Toggle Terminal**: Ctrl+` (or Cmd+`)
- **New File**: Ctrl+N (or Cmd+N)

## 🔧 Mobile Troubleshooting

### Connection Issues
1. **Check Network**: Ensure mobile device has internet
2. **Verify IP**: Confirm server IP address is correct
3. **Firewall**: Check firewall settings on server
4. **Port Access**: Ensure port 8080/8443 is accessible

### Performance Optimization
1. **Close Other Apps**: Free up mobile memory
2. **Use Wi-Fi**: Better performance than cellular
3. **Browser Cache**: Clear browser cache if slow
4. **Mesh Connection**: Use VPN for better stability

### Common Mobile Issues

#### Keyboard Not Showing
- Tap in text areas to trigger keyboard
- Try different browsers
- Check browser settings for keyboard

#### Touch Scrolling Problems
- Use two-finger scroll in editor
- Try different browsers
- Adjust browser zoom level

#### Copilot Not Working
- Sign in to GitHub in mobile browser
- Check GitHub Copilot subscription
- Ensure internet connectivity

## 📊 Mobile Performance Tips

### Battery Optimization
- **Reduce Screen Brightness**: Save battery during long sessions
- **Close Background Apps**: Free up system resources
- **Use Dark Mode**: Better for OLED screens and battery
- **Disable Auto-Lock**: Prevent screen from turning off

### Data Usage
- **Use Wi-Fi**: Avoid cellular data charges
- **Mesh VPN**: Efficient data usage through compression
- **Cache Files**: Browser caches frequently used files

## 🎮 Advanced Mobile Features

### iPad Pro Development
- **External Monitor**: Connect to external display
- **Magic Keyboard**: Full keyboard experience
- **Apple Pencil**: Annotate code and diagrams
- **Split View**: VS Code + documentation side-by-side

### Android Tablet Features
- **DeX Mode**: Samsung DeX for desktop-like experience
- **External Keyboard**: Bluetooth keyboard support
- **Multi-Window**: Run multiple browser windows
- **Stylus Support**: Use stylus for precise editing

## 📈 Mobile Development Metrics

### Track Your Mobile Productivity
- **Code Commits**: Track commits made from mobile
- **Time Spent**: Monitor mobile development time
- **Feature Usage**: Which features you use most on mobile
- **Performance**: Mobile vs desktop productivity

---

## 🔗 Related Documentation

- [VS Code Integration](./VSCODE_INTEGRATION.md) - Local and web VS Code setup
- [Mesh VPN Overview](../mesh/MESH_OVERVIEW.md) - VPN setup and management
- [Copilot Setup](./COPILOT_SETUP.md) - AI assistance on mobile
