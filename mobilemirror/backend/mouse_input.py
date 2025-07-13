#!/usr/bin/env python3
"""
Mobile Mirror Mouse Input Module
===============================

Provides secure mouse input simulation for mobile-to-desktop control.
Uses xdotool to translate mobile touch events into desktop mouse actions.

Features:
- Mouse movement simulation
- Click event simulation
- Coordinate validation and bounds checking
- Security controls to prevent abuse
- Comprehensive logging and audit trail
- Performance monitoring

Security Considerations:
- Input validation for coordinates
- Rate limiting to prevent spam
- Logging all mouse actions for audit
- Bounds checking to prevent out-of-screen actions
"""

import subprocess
import time
from typing import Dict, Any, Optional, Tuple
from datetime import datetime, timedelta

from .utils.logger import get_logger, log_performance

# Initialize module logger
logger = get_logger(__name__)

# Security and performance settings
MAX_ACTIONS_PER_SECOND = 50
MAX_ACTIONS_PER_MINUTE = 1000
SCREEN_BOUNDS_CACHE_TTL = 30  # seconds

# Rate limiting tracking
action_timestamps = []
screen_bounds_cache = {"bounds": None, "timestamp": None}

class MouseInputError(Exception):
    """Custom exception for mouse input errors"""
    pass

def get_screen_bounds() -> Tuple[int, int]:
    """
    Get current screen resolution with caching
    
    Returns:
        Tuple of (width, height)
    """
    global screen_bounds_cache
    
    # Check cache validity
    now = datetime.now()
    if (screen_bounds_cache["timestamp"] and 
        screen_bounds_cache["bounds"] and
        (now - screen_bounds_cache["timestamp"]).total_seconds() < SCREEN_BOUNDS_CACHE_TTL):
        return screen_bounds_cache["bounds"]
    
    try:
        # Get screen dimensions using xdpyinfo
        result = subprocess.run(
            ["xdpyinfo"], 
            capture_output=True, 
            text=True, 
            check=True,
            timeout=5
        )
        
        # Parse dimensions from output
        for line in result.stdout.split('\n'):
            if 'dimensions:' in line:
                # Example: "  dimensions:    1920x1080 pixels (508x285 millimeters)"
                dims = line.split()[1].split('x')
                width = int(dims[0])
                height = int(dims[1].split('p')[0])  # Remove 'pixels' suffix
                
                screen_bounds_cache = {
                    "bounds": (width, height),
                    "timestamp": now
                }
                
                logger.debug(f"Screen bounds detected: {width}x{height}")
                return (width, height)
        
        # Fallback if parsing fails
        logger.warning("Could not parse screen dimensions, using default")
        return (1920, 1080)
        
    except Exception as e:
        logger.error("Failed to get screen bounds", exc_info=True)
        return (1920, 1080)  # Safe default

def check_rate_limit() -> bool:
    """
    Check if action is within rate limits
    
    Returns:
        True if action is allowed, False if rate limited
    """
    global action_timestamps
    
    now = datetime.now()
    
    # Remove timestamps older than 1 minute
    action_timestamps = [ts for ts in action_timestamps if (now - ts).total_seconds() < 60]
    
    # Check per-minute limit
    if len(action_timestamps) >= MAX_ACTIONS_PER_MINUTE:
        logger.warning("Rate limit exceeded: too many actions per minute")
        return False
    
    # Check per-second limit
    recent_actions = [ts for ts in action_timestamps if (now - ts).total_seconds() < 1]
    if len(recent_actions) >= MAX_ACTIONS_PER_SECOND:
        logger.warning("Rate limit exceeded: too many actions per second")
        return False
    
    # Record this action
    action_timestamps.append(now)
    return True

def validate_coordinates(x: int, y: int) -> bool:
    """
    Validate mouse coordinates are within screen bounds
    
    Args:
        x: X coordinate
        y: Y coordinate
        
    Returns:
        True if coordinates are valid
    """
    if x < 0 or y < 0:
        logger.warning(f"Invalid coordinates: negative values ({x}, {y})")
        return False
    
    width, height = get_screen_bounds()
    
    if x >= width or y >= height:
        logger.warning(f"Coordinates out of bounds: ({x}, {y}) vs screen ({width}x{height})")
        return False
    
    return True

@log_performance
def move_mouse(x: Optional[int] = None, y: Optional[int] = None, 
               click: bool = False, button: int = 1) -> Dict[str, Any]:
    """
    Simulate mouse movement and/or clicking
    
    Args:
        x: X coordinate (None to skip movement)
        y: Y coordinate (None to skip movement)
        click: Whether to perform a click
        button: Mouse button (1=left, 2=middle, 3=right)
        
    Returns:
        Dictionary containing operation status and details
    """
    logger.debug(f"Mouse action requested: move=({x}, {y}), click={click}, button={button}")
    
    try:
        # Rate limiting check
        if not check_rate_limit():
            return {
                "status": "error",
                "error": "Rate limit exceeded",
                "action": "move_mouse"
            }
        
        # Validate inputs
        if button not in [1, 2, 3]:
            logger.warning(f"Invalid mouse button: {button}")
            return {
                "status": "error", 
                "error": "Invalid mouse button",
                "button": button
            }
        
        # Validate coordinates if movement requested
        if x is not None and y is not None:
            if not validate_coordinates(x, y):
                return {
                    "status": "error",
                    "error": "Invalid coordinates",
                    "x": x,
                    "y": y
                }
        
        # Perform mouse movement
        if x is not None and y is not None:
            try:
                subprocess.run(
                    ["xdotool", "mousemove", str(x), str(y)], 
                    check=True,
                    timeout=2
                )
                logger.info(f"Mouse moved to ({x}, {y})")
            except subprocess.CalledProcessError as e:
                logger.error(f"Failed to move mouse to ({x}, {y})", exc_info=True)
                return {
                    "status": "error",
                    "error": f"Mouse movement failed: {e}",
                    "x": x,
                    "y": y
                }
        
        # Perform mouse click
        if click:
            try:
                subprocess.run(
                    ["xdotool", "click", str(button)], 
                    check=True,
                    timeout=2
                )
                logger.info(f"Mouse button {button} clicked at ({x}, {y})")
            except subprocess.CalledProcessError as e:
                logger.error(f"Failed to click mouse button {button}", exc_info=True)
                return {
                    "status": "error",
                    "error": f"Mouse click failed: {e}",
                    "button": button
                }
        
        # Return success status
        result: Dict[str, Any] = {
            "status": "success",
            "action": "mouse_input",
            "timestamp": datetime.now().isoformat()
        }
        
        if x is not None and y is not None:
            result["x"] = x
            result["y"] = y
            result["moved"] = True
        else:
            result["moved"] = False
            
        if click:
            result["clicked"] = True
            result["button"] = button
        else:
            result["clicked"] = False
        
        return result
        
    except subprocess.TimeoutExpired:
        logger.error("Mouse action timed out")
        return {
            "status": "error",
            "error": "Operation timed out"
        }
    except Exception as e:
        logger.error("Unexpected error in mouse input", exc_info=True, extra={
            "x": x,
            "y": y,
            "click": click,
            "button": button,
            "error_type": type(e).__name__
        })
        return {
            "status": "error",
            "error": f"Unexpected error: {str(e)}"
        }

def get_mouse_stats() -> Dict[str, Any]:
    """Get mouse input statistics and status"""
    now = datetime.now()
    recent_actions = [ts for ts in action_timestamps if (now - ts).total_seconds() < 60]
    
    width, height = get_screen_bounds()
    
    return {
        "screen_resolution": {"width": width, "height": height},
        "rate_limiting": {
            "actions_last_minute": len(recent_actions),
            "max_per_minute": MAX_ACTIONS_PER_MINUTE,
            "max_per_second": MAX_ACTIONS_PER_SECOND
        },
        "tools_available": {
            "xdotool": check_xdotool_available()
        }
    }

def check_xdotool_available() -> bool:
    """Check if xdotool is available on the system"""
    try:
        subprocess.run(["which", "xdotool"], check=True, capture_output=True)
        return True
    except subprocess.CalledProcessError:
        logger.warning("xdotool not found on system")
        return False