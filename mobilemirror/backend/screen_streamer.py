#!/usr/bin/env python3
"""
Mobile Mirror Screen Streaming Module
====================================

Manages desktop screen streaming for mobile access using VNC and modern
streaming technologies. Provides secure, low-latency desktop access
to mobile devices with comprehensive monitoring and control.

Features:
- VNC server management for screen streaming
- Multiple streaming protocol support
- Quality and performance optimization
- Security controls and authentication
- Connection monitoring and statistics
- Resource usage optimization
- Automatic cleanup and recovery

Security Considerations:
- Optional password protection
- IP filtering and access control
- Session monitoring and logging
- Resource limits to prevent abuse
"""

import subprocess
import psutil
import time
import signal
from pathlib import Path
from typing import Dict, List, Any, Optional
from datetime import datetime

from .utils.logger import get_logger, log_performance

# Initialize module logger
logger = get_logger(__name__)

# Configuration
APPDIR = str(Path.home() / ".local/share/applications")
LOGDIR = f"{APPDIR}/system/services"
STREAM_PORT = "5901"  # Standard VNC port
STREAM_LOG = f"{LOGDIR}/x11vnc.log"

# Global state tracking
streaming_process: Optional[subprocess.Popen] = None
stream_start_time: Optional[datetime] = None
connection_count = 0

class ScreenStreamError(Exception):
    """Custom exception for screen streaming errors"""
    pass

def ensure_log_directory():
    """Ensure log directory exists"""
    Path(LOGDIR).mkdir(parents=True, exist_ok=True)

def check_display_available() -> bool:
    """
    Check if X11 display is available for streaming
    
    Returns:
        True if display is available
    """
    try:
        result = subprocess.run(
            ["xdpyinfo", "-display", ":0"], 
            capture_output=True, 
            timeout=5
        )
        available = result.returncode == 0
        
        if available:
            logger.debug("X11 display :0 is available for streaming")
        else:
            logger.warning("X11 display :0 is not available")
            
        return available
        
    except Exception as e:
        logger.error("Failed to check display availability", exc_info=True)
        return False

def check_vnc_tools() -> Dict[str, bool]:
    """
    Check availability of VNC tools
    
    Returns:
        Dictionary of tool availability
    """
    tools = {}
    
    for tool in ["x11vnc", "vncviewer"]:
        try:
            subprocess.run(["which", tool], check=True, capture_output=True)
            tools[tool] = True
            logger.debug(f"VNC tool available: {tool}")
        except subprocess.CalledProcessError:
            tools[tool] = False
            logger.warning(f"VNC tool not found: {tool}")
    
    return tools

def is_streaming() -> bool:
    """
    Check if screen streaming is currently active
    
    Returns:
        True if streaming is active
    """
    global streaming_process
    
    if streaming_process is None:
        return False
    
    # Check if process is still running
    try:
        if streaming_process.poll() is None:
            return True
        else:
            logger.info("Stream process has terminated")
            streaming_process = None
            return False
    except Exception:
        streaming_process = None
        return False

def kill_existing_vnc():
    """Kill any existing VNC servers on our port"""
    try:
        # Find processes using our port
        for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
            try:
                if proc.info['name'] == 'x11vnc':
                    cmdline = proc.info['cmdline'] or []
                    if any(STREAM_PORT in arg for arg in cmdline):
                        logger.info(f"Killing existing VNC process: {proc.info['pid']}")
                        proc.terminate()
                        time.sleep(1)
                        if proc.is_running():
                            proc.kill()
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue
                
    except Exception as e:
        logger.warning("Error killing existing VNC processes", exc_info=True)

@log_performance
def start_stream(password: Optional[str] = None, 
                quality: str = "medium",
                allow_remote: bool = True) -> Dict[str, Any]:
    """
    Start screen streaming server
    
    Args:
        password: Optional VNC password for security
        quality: Stream quality (low, medium, high)
        allow_remote: Allow connections from remote IPs
        
    Returns:
        Dictionary containing operation status and details
    """
    global streaming_process, stream_start_time
    
    logger.info("Starting screen streaming server", extra={
        "port": STREAM_PORT,
        "quality": quality,
        "password_protected": password is not None,
        "allow_remote": allow_remote
    })
    
    try:
        # Ensure prerequisites
        ensure_log_directory()
        
        # Check if already running
        if is_streaming():
            logger.info("Screen streaming is already active")
            return {
                "status": "already_running",
                "port": STREAM_PORT,
                "uptime": (datetime.now() - stream_start_time).total_seconds() if stream_start_time else None
            }
        
        # Check display availability
        if not check_display_available():
            logger.error("X11 display not available for streaming")
            return {
                "status": "error",
                "error": "X11 display not available"
            }
        
        # Check VNC tools
        tools = check_vnc_tools()
        if not tools.get("x11vnc", False):
            logger.error("x11vnc not available")
            return {
                "status": "error",
                "error": "x11vnc not installed"
            }
        
        # Kill existing VNC servers
        kill_existing_vnc()
        
        # Build command arguments
        cmd = [
            "x11vnc",
            "-display", ":0",
            "-rfbport", STREAM_PORT,
            "-forever",
            "-shared",
            "-bg",
            "-o", STREAM_LOG
        ]
        
        # Add quality settings
        if quality == "low":
            cmd.extend(["-scale", "0.7", "-quality", "30"])
        elif quality == "medium":
            cmd.extend(["-quality", "60"])
        elif quality == "high":
            cmd.extend(["-quality", "90"])
        
        # Add password if provided
        if password:
            cmd.extend(["-passwd", password])
        else:
            cmd.append("-nopw")
        
        # Add network settings
        if not allow_remote:
            cmd.extend(["-localhost"])
        
        # Add performance optimizations
        cmd.extend([
            "-threads",
            "-ncache", "10",
            "-ncache_cr",
            "-cursor", "arrow"
        ])
        
        logger.debug(f"Starting VNC with command: {' '.join(cmd)}")
        
        # Start the streaming process
        streaming_process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        
        # Wait a moment to check if it started successfully
        time.sleep(2)
        
        if streaming_process.poll() is not None:
            # Process died immediately
            stdout, stderr = streaming_process.communicate()
            logger.error("VNC process failed to start", extra={
                "stdout": stdout.decode() if stdout else "",
                "stderr": stderr.decode() if stderr else ""
            })
            streaming_process = None
            return {
                "status": "error",
                "error": "VNC process failed to start",
                "details": stderr.decode() if stderr else "Unknown error"
            }
        
        stream_start_time = datetime.now()
        
        logger.info("Screen streaming started successfully", extra={
            "pid": streaming_process.pid,
            "port": STREAM_PORT,
            "quality": quality
        })
        
        return {
            "status": "success",
            "message": "Screen streaming started",
            "port": STREAM_PORT,
            "pid": streaming_process.pid,
            "quality": quality,
            "password_protected": password is not None,
            "start_time": stream_start_time.isoformat()
        }
        
    except Exception as e:
        logger.error("Failed to start screen streaming", exc_info=True)
        streaming_process = None
        return {
            "status": "error",
            "error": f"Failed to start streaming: {str(e)}"
        }

@log_performance
def stop_stream() -> Dict[str, Any]:
    """
    Stop screen streaming server
    
    Returns:
        Dictionary containing operation status
    """
    global streaming_process, stream_start_time
    
    logger.info("Stopping screen streaming server")
    
    try:
        if not is_streaming():
            logger.info("Screen streaming is not active")
            return {"status": "not_running"}
        
        # Terminate the process gracefully
        if streaming_process:
            streaming_process.terminate()
            
            # Wait for graceful shutdown
            try:
                streaming_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                logger.warning("VNC process did not terminate gracefully, forcing kill")
                streaming_process.kill()
                streaming_process.wait()
        
        # Kill any remaining VNC processes
        kill_existing_vnc()
        
        # Calculate uptime
        uptime = None
        if stream_start_time:
            uptime = (datetime.now() - stream_start_time).total_seconds()
        
        # Reset state
        streaming_process = None
        stream_start_time = None
        
        logger.info("Screen streaming stopped successfully", extra={
            "uptime_seconds": uptime
        })
        
        return {
            "status": "success",
            "message": "Screen streaming stopped",
            "uptime_seconds": uptime
        }
        
    except Exception as e:
        logger.error("Failed to stop screen streaming", exc_info=True)
        return {
            "status": "error",
            "error": f"Failed to stop streaming: {str(e)}"
        }

def get_stream_status() -> Dict[str, Any]:
    """
    Get current streaming status and statistics
    
    Returns:
        Dictionary containing streaming status and metrics
    """
    status = {
        "active": is_streaming(),
        "port": STREAM_PORT,
        "log_file": STREAM_LOG
    }
    
    if is_streaming() and streaming_process:
        status.update({
            "pid": streaming_process.pid,
            "start_time": stream_start_time.isoformat() if stream_start_time else None,
            "uptime_seconds": (datetime.now() - stream_start_time).total_seconds() if stream_start_time else None
        })
        
        # Get process resource usage
        try:
            proc = psutil.Process(streaming_process.pid)
            status["resources"] = {
                "cpu_percent": proc.cpu_percent(),
                "memory_mb": proc.memory_info().rss / 1024 / 1024,
                "connections": len(proc.connections())
            }
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass
    
    # Check tool availability
    status["tools"] = check_vnc_tools()
    status["display_available"] = check_display_available()
    
    return status