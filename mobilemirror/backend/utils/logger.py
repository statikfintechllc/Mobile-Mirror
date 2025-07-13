#!/usr/bin/env python3
"""
Mobile Mirror Centralized Logging System
========================================

Provides comprehensive logging functionality for all Mobile Mirror components:
- Multiple log levels (DEBUG, INFO, WARNING, ERROR, CRITICAL)
- Module-specific loggers with context
- Centralized configuration and log rotation
- Performance monitoring and metrics
- Error tracking with stack traces
- Structured logging with JSON support

Usage:
    from mobilemirror.backend.utils.logger import get_logger
    
    logger = get_logger(__name__)
    logger.info("Starting application")
    logger.error("Error occurred", exc_info=True)
"""

import logging
import logging.handlers
import json
import sys
import traceback
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Any
import threading
from functools import wraps

# Global configuration
LOG_DIR = Path.home() / ".local/share/mobilemirror/logs"
LOG_FORMAT = "[%(asctime)s] [%(name)s] [%(levelname)s] %(message)s"
JSON_FORMAT = True  # Enable structured JSON logging

# Ensure log directory exists
LOG_DIR.mkdir(parents=True, exist_ok=True)

# Global logger registry
_loggers: Dict[str, logging.Logger] = {}
_lock = threading.Lock()

class MobileMirrorFormatter(logging.Formatter):
    """Custom formatter with JSON support and enhanced metadata"""
    
    def __init__(self, use_json=False):
        super().__init__()
        self.use_json = use_json
        
    def format(self, record):
        if self.use_json:
            return self._format_json(record)
        else:
            return self._format_text(record)
    
    def _format_json(self, record):
        """Format log record as JSON with metadata"""
        log_data = {
            "timestamp": datetime.fromtimestamp(record.created).isoformat(),
            "level": record.levelname,
            "module": record.name,
            "message": record.getMessage(),
            "filename": record.filename,
            "line": record.lineno,
            "thread": record.thread,
            "process": record.process
        }
        
        # Add exception info if present
        if record.exc_info:
            log_data["exception"] = {
                "type": record.exc_info[0].__name__ if record.exc_info[0] else None,
                "message": str(record.exc_info[1]) if record.exc_info[1] else None,
                "traceback": traceback.format_exception(*record.exc_info)
            }
        
        # Add extra fields
        for key, value in record.__dict__.items():
            if key not in ['name', 'msg', 'args', 'levelname', 'levelno', 'pathname', 
                          'filename', 'module', 'lineno', 'funcName', 'created', 
                          'msecs', 'relativeCreated', 'thread', 'threadName', 
                          'processName', 'process', 'getMessage', 'exc_info', 'exc_text', 'stack_info']:
                log_data[key] = value
        
        return json.dumps(log_data, default=str)
    
    def _format_text(self, record):
        """Format log record as human-readable text"""
        formatted = f"[{datetime.fromtimestamp(record.created).strftime('%Y-%m-%d %H:%M:%S')}] "
        formatted += f"[{record.name}] [{record.levelname}] "
        formatted += f"{record.getMessage()}"
        
        # Add location info for DEBUG level
        if record.levelno == logging.DEBUG:
            formatted += f" ({record.filename}:{record.lineno})"
        
        return formatted

def get_logger(name: str, level: str = "INFO") -> logging.Logger:
    """
    Get or create a logger for the specified module
    
    Args:
        name: Logger name (typically __name__)
        level: Log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
    
    Returns:
        Configured logger instance
    """
    with _lock:
        if name in _loggers:
            return _loggers[name]
        
        logger = logging.getLogger(name)
        logger.setLevel(getattr(logging, level.upper()))
        
        # Remove existing handlers to avoid duplicates
        for handler in logger.handlers[:]:
            logger.removeHandler(handler)
        
        # File handler with rotation
        file_handler = logging.handlers.RotatingFileHandler(
            LOG_DIR / "mobilemirror.log",
            maxBytes=10*1024*1024,  # 10MB
            backupCount=5
        )
        file_handler.setFormatter(MobileMirrorFormatter(use_json=JSON_FORMAT))
        logger.addHandler(file_handler)
        
        # Console handler for development
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setFormatter(MobileMirrorFormatter(use_json=False))
        logger.addHandler(console_handler)
        
        # Error file handler
        error_handler = logging.handlers.RotatingFileHandler(
            LOG_DIR / "errors.log",
            maxBytes=5*1024*1024,  # 5MB
            backupCount=3
        )
        error_handler.setLevel(logging.ERROR)
        error_handler.setFormatter(MobileMirrorFormatter(use_json=JSON_FORMAT))
        logger.addHandler(error_handler)
        
        _loggers[name] = logger
        return logger

def log_performance(func):
    """Decorator to log function performance metrics"""
    @wraps(func)
    def wrapper(*args, **kwargs):
        logger = get_logger(f"{func.__module__}.{func.__name__}")
        start_time = datetime.now()
        
        logger.debug(f"Starting {func.__name__}", extra={
            "function": func.__name__,
            "args_count": len(args),
            "kwargs_count": len(kwargs)
        })
        
        try:
            result = func(*args, **kwargs)
            duration = (datetime.now() - start_time).total_seconds()
            
            logger.info(f"Completed {func.__name__}", extra={
                "function": func.__name__,
                "duration_seconds": duration,
                "status": "success"
            })
            
            return result
        except Exception as e:
            duration = (datetime.now() - start_time).total_seconds()
            
            logger.error(f"Failed {func.__name__}", extra={
                "function": func.__name__,
                "duration_seconds": duration,
                "status": "error",
                "error_type": type(e).__name__
            }, exc_info=True)
            
            raise
    
    return wrapper

def log_api_request(func):
    """Decorator to log API requests and responses"""
    @wraps(func)
    def wrapper(*args, **kwargs):
        logger = get_logger(f"api.{func.__name__}")
        
        # Extract request info if available
        request_info = {}
        for arg in args:
            if hasattr(arg, 'method') and hasattr(arg, 'url'):
                request_info = {
                    "method": arg.method,
                    "path": str(arg.url.path) if arg.url else "unknown",
                    "client": arg.client.host if hasattr(arg, 'client') else "unknown"
                }
                break
        
        logger.info(f"API Request: {func.__name__}", extra={
            "endpoint": func.__name__,
            **request_info
        })
        
        try:
            result = func(*args, **kwargs)
            logger.info(f"API Response: {func.__name__}", extra={
                "endpoint": func.__name__,
                "status": "success"
            })
            return result
        except Exception as e:
            logger.error(f"API Error: {func.__name__}", extra={
                "endpoint": func.__name__,
                "error_type": type(e).__name__
            }, exc_info=True)
            raise
    
    return wrapper

# Legacy compatibility function
def log_event(msg: str, inline: bool = False, level: str = "INFO"):
    """
    Legacy compatibility function for existing code
    
    Args:
        msg: Log message
        inline: If True, return recent log lines (legacy feature)
        level: Log level
    """
    logger = get_logger("legacy")
    
    # Map to appropriate log level
    log_func = getattr(logger, level.lower(), logger.info)
    log_func(msg)
    
    if inline:
        try:
            log_file = LOG_DIR / "mobilemirror.log"
            if log_file.exists():
                with open(log_file, "r", encoding="utf-8") as f:
                    return "".join(f.readlines()[-50:])
        except Exception:
            return "[Log unavailable]"
        return ""

def get_log_stats() -> Dict[str, Any]:
    """Get logging statistics and metrics"""
    stats = {
        "log_directory": str(LOG_DIR),
        "active_loggers": len(_loggers),
        "logger_names": list(_loggers.keys()),
        "log_files": []
    }
    
    # Get log file information
    for log_file in LOG_DIR.glob("*.log"):
        try:
            file_stats = log_file.stat()
            stats["log_files"].append({
                "name": log_file.name,
                "size_bytes": file_stats.st_size,
                "size_mb": round(file_stats.st_size / (1024*1024), 2),
                "modified": datetime.fromtimestamp(file_stats.st_mtime).isoformat()
            })
        except Exception:
            continue
    
    return stats

# Initialize main logger
main_logger = get_logger("mobilemirror")
main_logger.info("Mobile Mirror logging system initialized", extra={
    "log_directory": str(LOG_DIR),
    "json_format": JSON_FORMAT
})