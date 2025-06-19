# Mobile-Developer: TouchCore

**Structure Build-Out:**

```text
Mobile-Developer/
│
├── env/
│   ├── MobileDeveloper.desktop
│   ├── MobileDeveloper.png
│   ├── .env.example
│   ├── apt.txt
│   └── install.sh
│
├── scripts/
│   ├── remove_mobile.sh
│   ├── start_all.sh           # 🔁 Starts both code-server + TouchCore
│   ├── stop_all.sh
│   └── mobile_cli.sh
│
├── touchcore/                 # 🔥 New Subsystem
│   ├── backend/
│   │   ├── app.py
│   │   ├── screen_streamer.py
│   │   ├── file_ops.py
│   │   ├── terminal_bridge.py
│   │   ├── mouse_input.py
│   │   └── utils/
│   │       ├── auth.py
│   │       ├── qr_generator.py
│   │       └── logger.py
│   ├── frontend/
│   │   ├── public/
│   │   │   └── manifest.json
│   │   └── src/
│   │       ├── App.jsx
│   │       ├── Terminal.jsx
│   │       ├── Editor.jsx
│   │       ├── FileManager.jsx
│   │       ├── ScreenView.jsx
│   │       ├── MouseController.js
│   │       └── api.js
│   ├── config/
│   │   ├── system.toml
│   │   └── tailscale_setup.sh
│   ├── system
│   │   └── services
│   └── start_touchcore.sh     # 👈 Optional standalone start script
│
├── system/                    # 🧠 Runtime and service layer
│   ├── code-server/           # Optional VS Code mirror or cache
│   ├── x11vnc/                # VNC or ffmpeg screen stream configs
│   ├── tailscale/             # Auth state & PID tracking
│   └── services/              # Daemon logs, lockfiles, .pid flags
│
├── docs/
│   ├── README.md
│   ├── SYSTEM_OVERVIEW.md
│   └── STRUCTURE.md
│
└── LICENSE                    # Open-use: Gremlin-style
```
