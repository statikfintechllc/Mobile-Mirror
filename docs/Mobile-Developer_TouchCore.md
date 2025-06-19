# Mobile-Developer: TouchCore

**Structure Build-Out:**

```text
Mobile-Developer: TouchCore/
│
├── env/
│   │
│   ├── MobileDeveloper.desktop
│   ├── MobileDeveloper.png
│   ├── .env.example
│   ├── apt.txt
│   └── install.sh
│
├── scripts/
│   │
│   ├── remove_mobile.sh
│   ├── start_all.sh           # 🔁 Starts both code-server + TouchCore
│   ├── stop_all.sh
│   └── mobile_cli.sh
│
├── touchcore/                 # 🔥 New SubSystem
│   │
│   ├── backend/
│   │   │
│   │   ├── app.py
│   │   ├── screen_streamer.py
│   │   ├── file_ops.py
│   │   ├── terminal_bridge.py
│   │   ├── mouse_input.py
│   │   └── utils/
│   │       │
│   │       ├── auth.py
│   │       ├── qr_generator.py
│   │       └── logger.py
│   │
│   ├── frontend/
│   │   │
│   │   ├── public/
│   │   │   │ 
│   │   │   └── manifest.json
│   │   │
│   │   └── src/
│   │       │
│   │       ├── App.jsx
│   │       ├── Terminal.jsx
│   │       ├── Editor.jsx
│   │       ├── FileManager.jsx
│   │       ├── ScreenView.jsx
│   │       ├── MouseController.js
│   │       └── api.js
│   │   
│   ├── config/
│   │   │
│   │   ├── system.toml
│   │   └── tailscale_setup.sh
│   │   
│   ├── system
│   │   │   
│   │   └── services
│   │       │
│   │       ├── touchcore_backend.log
│   │       └── touchcore_frontend.log
│   │
│   └── start_touchcore.sh  # 👈 Optional standalone start script
│
├── docs/
│   │
│   ├── README.md
│   ├── SYSTEM_OVERVIEW.md
│   └── STRUCTURE.md
│
└── LICENSE                    # Open-use: GodaCore-style
```
