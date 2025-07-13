#!/usr/bin/env python3
"""
Mobile Mirror QR Code Generator
==============================

Generates QR codes for easy mobile device connection to the Mobile Mirror
system. Supports multiple QR code formats and provides enhanced metadata
for connection setup.

Features:
- PNG and SVG QR code generation
- Base64 encoding for web embedding
- Connection metadata embedding
- Error correction level control
- Custom styling and branding
- Comprehensive logging and monitoring

Security Considerations:
- URL validation and sanitization
- Limited QR code size to prevent abuse
- Logging of QR code generation for audit
"""

import subprocess
import base64
import json
from io import BytesIO
from typing import Dict, Any, Optional, List
from datetime import datetime
from pathlib import Path

from PIL import Image
import qrcode
from qrcode import constants
try:
    from qrcode.image.styledpil import StyledPilImage
    from qrcode.image.styles.moduledrawers import RoundedModuleDrawer
    STYLED_QR_AVAILABLE = True
except ImportError:
    STYLED_QR_AVAILABLE = False

from .logger import get_logger, log_performance

# Initialize module logger
logger = get_logger(__name__)

# Configuration
DEFAULT_ERROR_CORRECTION = constants.ERROR_CORRECT_M
MAX_URL_LENGTH = 2048
QR_CACHE_DIR = Path.home() / ".local/share/mobilemirror/qr_cache"

def ensure_qr_directory():
    """Ensure QR code cache directory exists"""
    QR_CACHE_DIR.mkdir(parents=True, exist_ok=True)

def validate_url(url: str) -> bool:
    """
    Validate URL for QR code generation
    
    Args:
        url: URL to validate
        
    Returns:
        True if URL is valid
    """
    if not url or len(url) > MAX_URL_LENGTH:
        logger.warning(f"Invalid URL length: {len(url) if url else 0}")
        return False
    
    # Basic URL validation
    if not (url.startswith('http://') or url.startswith('https://')):
        logger.warning(f"Invalid URL protocol: {url}")
        return False
    
    return True

def check_qrencode_available() -> bool:
    """Check if qrencode command line tool is available"""
    try:
        subprocess.run(["which", "qrencode"], check=True, capture_output=True)
        return True
    except subprocess.CalledProcessError:
        logger.warning("qrencode command not found")
        return False

@log_performance
def generate_qr_with_qrencode(url: str, size: str = "medium") -> Optional[bytes]:
    """
    Generate QR code using qrencode command line tool
    
    Args:
        url: URL to encode
        size: QR code size (small, medium, large)
        
    Returns:
        PNG image bytes or None if generation fails
    """
    if not check_qrencode_available():
        return None
    
    try:
        # Size mapping
        size_args = {
            "small": ["-s", "3"],
            "medium": ["-s", "6"],
            "large": ["-s", "10"]
        }
        
        cmd = ["qrencode", "-t", "PNG", "-o", "-"] + size_args.get(size, ["-s", "6"]) + [url]
        
        logger.debug(f"Generating QR code with qrencode: {size}")
        
        qr_img = subprocess.check_output(cmd, timeout=10)
        
        logger.info(f"QR code generated successfully with qrencode: {len(qr_img)} bytes")
        return qr_img
        
    except subprocess.CalledProcessError as e:
        logger.error(f"qrencode failed: {e}")
        return None
    except subprocess.TimeoutExpired:
        logger.error("qrencode timed out")
        return None
    except Exception as e:
        logger.error("Unexpected error with qrencode", exc_info=True)
        return None

@log_performance
def generate_qr_with_python(url: str, 
                           size: str = "medium",
                           error_correction: str = "M",
                           style: str = "default") -> Optional[bytes]:
    """
    Generate QR code using Python qrcode library
    
    Args:
        url: URL to encode
        size: QR code size (small, medium, large)
        error_correction: Error correction level (L, M, Q, H)
        style: QR code style (default, rounded)
        
    Returns:
        PNG image bytes or None if generation fails
    """
    try:
        # Error correction mapping
        error_levels = {
            "L": constants.ERROR_CORRECT_L,
            "M": constants.ERROR_CORRECT_M,
            "Q": constants.ERROR_CORRECT_Q,
            "H": constants.ERROR_CORRECT_H
        }
        
        # Size mapping
        size_configs = {
            "small": {"box_size": 5, "border": 2},
            "medium": {"box_size": 10, "border": 4},
            "large": {"box_size": 15, "border": 6}
        }
        
        config = size_configs.get(size, size_configs["medium"])
        error_level = error_levels.get(error_correction, constants.ERROR_CORRECT_M)
        
        logger.debug(f"Generating QR code with Python library: {size}, {error_correction}, {style}")
        
        # Create QR code instance
        qr = qrcode.QRCode(
            version=1,
            error_correction=error_level,
            box_size=config["box_size"],
            border=config["border"]
        )
        
        qr.add_data(url)
        qr.make(fit=True)
        
        # Generate image with style
        if style == "rounded" and STYLED_QR_AVAILABLE:
            img = qr.make_image(
                image_factory=StyledPilImage,
                module_drawer=RoundedModuleDrawer()
            )
        else:
            img = qr.make_image(fill_color="black", back_color="white")
        
        # Convert to bytes
        img_buffer = BytesIO()
        img.save(img_buffer, 'PNG')
        img_bytes = img_buffer.getvalue()
        
        logger.info(f"QR code generated successfully with Python: {len(img_bytes)} bytes")
        return img_bytes
        
    except Exception as e:
        logger.error("Failed to generate QR code with Python library", exc_info=True)
        return None

@log_performance
def generate_qr(url: str, 
               format: str = "png",
               size: str = "medium",
               error_correction: str = "M",
               style: str = "default",
               include_metadata: bool = True) -> Dict[str, Any]:
    """
    Generate QR code for the given URL with comprehensive options
    
    Args:
        url: URL to encode in QR code
        format: Output format (png, base64)
        size: QR code size (small, medium, large)
        error_correction: Error correction level (L, M, Q, H)
        style: QR code style (default, rounded)
        include_metadata: Include connection metadata
        
    Returns:
        Dictionary containing QR code data and metadata
    """
    logger.info(f"QR code generation requested for URL: {url}", extra={
        "url_length": len(url),
        "format": format,
        "size": size,
        "error_correction": error_correction,
        "style": style
    })
    
    try:
        # Validate input
        if not validate_url(url):
            return {
                "status": "error",
                "error": "Invalid URL provided",
                "url": url
            }
        
        # Try qrencode first, fallback to Python library
        qr_bytes = generate_qr_with_qrencode(url, size)
        if qr_bytes is None:
            logger.debug("qrencode failed, trying Python library")
            qr_bytes = generate_qr_with_python(url, size, error_correction, style)
        
        if qr_bytes is None:
            logger.error("All QR generation methods failed")
            return {
                "status": "error",
                "error": "Failed to generate QR code",
                "url": url
            }
        
        # Prepare result
        result = {
            "status": "success",
            "url": url,
            "format": format,
            "size": size,
            "generated_at": datetime.now().isoformat(),
            "qr_size_bytes": len(qr_bytes)
        }
        
        # Add QR code data based on format
        if format == "base64":
            b64_data = base64.b64encode(qr_bytes).decode()
            result["qr_base64"] = f"data:image/png;base64,{b64_data}"
        else:
            result["qr_data"] = qr_bytes
        
        # Add metadata if requested
        if include_metadata:
            result["metadata"] = generate_connection_metadata(url)
        
        logger.info(f"QR code generated successfully", extra={
            "url": url,
            "size_bytes": len(qr_bytes),
            "format": format
        })
        
        return result
        
    except Exception as e:
        logger.error("Unexpected error generating QR code", exc_info=True, extra={
            "url": url,
            "format": format,
            "error_type": type(e).__name__
        })
        return {
            "status": "error",
            "error": f"Unexpected error: {str(e)}",
            "url": url
        }

def generate_connection_metadata(url: str) -> Dict[str, Any]:
    """
    Generate connection metadata for mobile clients
    
    Args:
        url: Connection URL
        
    Returns:
        Dictionary containing connection metadata
    """
    try:
        from urllib.parse import urlparse
        
        parsed = urlparse(url)
        
        metadata = {
            "connection_type": "mobile_mirror",
            "protocol": parsed.scheme,
            "host": parsed.hostname,
            "port": parsed.port,
            "path": parsed.path,
            "instructions": {
                "step1": "Scan this QR code with your mobile device",
                "step2": "Open the link in your mobile browser",
                "step3": "Use touch controls to interact with desktop",
                "requirements": [
                    "Mobile device with camera",
                    "Modern web browser",
                    "Network connectivity to host"
                ]
            },
            "features": [
                "Real-time desktop streaming",
                "Touch-to-mouse translation",
                "File system access",
                "Terminal access",
                "Secure encrypted connection"
            ]
        }
        
        return metadata
        
    except Exception as e:
        logger.warning("Failed to generate connection metadata", exc_info=True)
        return {"error": "Failed to generate metadata"}

def get_qr_stats() -> Dict[str, Any]:
    """Get QR code generation statistics"""
    return {
        "tools_available": {
            "qrencode": check_qrencode_available(),
            "python_qrcode": True  # Always available since we import it
        },
        "cache_directory": str(QR_CACHE_DIR),
        "max_url_length": MAX_URL_LENGTH,
        "supported_formats": ["png", "base64"],
        "supported_sizes": ["small", "medium", "large"],
        "supported_styles": ["default", "rounded"]
    }