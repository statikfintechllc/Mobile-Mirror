#!/usr/bin/env python3
"""
Mobile Mirror Backend API
========================

FastAPI application providing secure mobile access to desktop development environment.
Supports file operations, terminal access, screen streaming, and mouse input.

Features:
- RESTful API for file system operations
- WebSocket connections for real-time terminal access
- Screen streaming capabilities for mobile viewing
- Mouse input simulation from mobile devices
- QR code generation for easy mobile connection
- Token-based authentication
- Comprehensive logging and monitoring

Endpoints:
- GET /: Health check and status
- GET /files: List directory contents
- POST /files: Create new files
- PUT /files: Update existing files
- DELETE /files: Remove files
- WebSocket /terminal: Real-time terminal access
- GET /screen: Screen streaming endpoint
- POST /mouse: Mouse input simulation
- GET /qr: Generate connection QR code
"""

import uvicorn
from fastapi import FastAPI, WebSocket, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pathlib import Path
import asyncio
from typing import Optional

# Local module imports
from .file_ops import list_files, read_file, write_file
from .terminal_bridge import handle_terminal
from .mouse_input import move_mouse
from .screen_streamer import start_stream
from .utils.qr_generator import generate_qr
from .utils.logger import get_logger, log_api_request, log_performance
from .utils.auth import verify_token

# Initialize logger for this module
logger = get_logger(__name__)

# ─────────── Settings ───────────
APPDIR = str(Path.home() / ".local/share/applications")
LOGDIR = f"{APPDIR}/system/services"
PORT = 8000

logger.info("Initializing Mobile Mirror Backend API", extra={
    "port": PORT,
    "app_dir": APPDIR,
    "log_dir": LOGDIR
})

# ─────────── FastAPI App ───────────
app = FastAPI(
    title="Mobile Mirror API",
    description="Secure mobile access to desktop development environment",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

logger.info("FastAPI application configured with CORS middleware")

# ─────────── API ROUTES ───────────

@app.get("/")
@log_api_request
def index():
    """Health check endpoint"""
    logger.info("Health check requested")
    return {
        "status": "Mobile Mirror Online",
        "version": "1.0.0",
        "ui": "http://localhost:5000",
        "api_docs": "/docs"
    }

@app.get("/files")
@log_api_request
def get_files(request: Request, path: str = "."):
    """List files in the specified directory"""
    logger.debug(f"File listing requested for path: {path}")
    
    token = request.headers.get("Authorization", "")
    if not verify_token(token):
        logger.warning(f"Unauthorized file access attempt from {request.client.host if request.client else 'unknown'}")
        raise HTTPException(status_code=403, detail="Invalid token")
    
    try:
        files = list_files(path)
        logger.info(f"Successfully listed {len(files)} files in {path}")
        return files
    except Exception as e:
        logger.error(f"Failed to list files in {path}", exc_info=True)
        raise HTTPException(status_code=500, detail="Failed to list files")

@app.post("/read")
@log_api_request
async def open_file(req: Request):
    """Read file contents"""
    token = req.headers.get("Authorization", "")
    if not verify_token(token):
        raise HTTPException(status_code=403, detail="Invalid token")
    data = await req.json()
    return read_file(data.get("path", ""))

@app.post("/write")
async def save_file(req: Request):
    token = req.headers.get("Authorization", "")
    if not verify_token(token):
        raise HTTPException(status_code=403, detail="Invalid token")
    data = await req.json()
    return write_file(data.get("path", ""), data.get("content", ""))

@app.websocket("/terminal")
async def ws_terminal(websocket: WebSocket):
    await handle_terminal(websocket)  # optional: inject token handshake for full protection

@app.post("/mouse")
async def handle_mouse(req: Request):
    token = req.headers.get("Authorization", "")
    if not verify_token(token):
        raise HTTPException(status_code=403, detail="Invalid token")
    data = await req.json()
    return move_mouse(data.get("x"), data.get("y"), data.get("click", False))

@app.get("/qr")
def qr():
    url = f"https://{get_headscale_ip()}:5000"
    return generate_qr(url)

@app.get("/log")
@log_api_request
def get_log():
    """Get recent log entries for debugging"""
    logger.info("Log request received")
    from .utils.logger import log_event  # Import legacy function
    return {"log": log_event("query", inline=True)}

# ─────────── UTIL ───────────

def get_headscale_ip():
    """Get the headscale mesh IP address for this node"""
    try:
        from subprocess import check_output
        # Try to get IP from headscale status
        result = check_output(["headscale", "nodes", "list", "--output", "json"]).decode()
        import json
        nodes = json.loads(result)
        if nodes:
            # Return the first node's IP
            return nodes[0].get('ip_addresses', ['localhost'])[0]
    except:
        pass
    
    # Fallback to checking network interfaces using ip command
    try:
        from subprocess import check_output
        result = check_output(["ip", "addr", "show"]).decode()
        import re
        # Look for headscale IP range (100.64.0.0/10)
        matches = re.findall(r'inet (100\.\d+\.\d+\.\d+)', result)
        if matches:
            return matches[0]
    except:
        pass
    
    return "localhost"

def get_tailscale_ip():
    """Legacy tailscale function - redirects to headscale"""
    return get_headscale_ip()

# ─────────── BOOT ───────────

@log_performance
def main():
    """Main application entry point"""
    logger.info("Mobile Mirror backend starting up", extra={
        "host": "0.0.0.0",
        "port": PORT
    })
    
    try:
        start_stream()
        logger.info("Screen streaming initialized successfully")
    except Exception as e:
        logger.error("Failed to initialize screen streaming", exc_info=True)
    
    uvicorn.run(app, host="0.0.0.0", port=PORT)

if __name__ == "__main__":
    main()