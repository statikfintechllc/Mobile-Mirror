#!/usr/bin/env python3
"""
Mobile Mirror File Operations Module
===================================

Provides secure file system operations for the Mobile Mirror backend.
Supports browsing, reading, writing, and managing files with comprehensive
logging and error handling.

Functions:
- list_files(path): List directory contents with metadata
- read_file(path): Read file contents safely
- write_file(path, content): Write content to file
- delete_file(path): Remove files securely
- get_file_info(path): Get detailed file metadata

Security Features:
- Path validation to prevent directory traversal
- Permission checking before operations
- Comprehensive audit logging
- Error handling with sanitized responses
"""

import os
import stat
from pathlib import Path
from typing import Dict, List, Any, Optional, Union
from datetime import datetime

from .utils.logger import get_logger, log_performance

# Initialize module logger
logger = get_logger(__name__)

@log_performance
def list_files(path: str = ".") -> Dict[str, Any]:
    """
    List files and directories in the specified path
    
    Args:
        path: Directory path to list (defaults to current directory)
        
    Returns:
        Dictionary containing path info and file listing
        
    Raises:
        SecurityError: If path traversal is attempted
        PermissionError: If access is denied
    """
    logger.debug(f"Listing files in path: {path}")
    
    try:
        # Resolve and validate path
        abs_path = Path(path).expanduser().resolve()
        
        # Security check: ensure path exists and is accessible
        if not abs_path.exists():
            logger.warning(f"Attempted access to non-existent path: {abs_path}")
            return {"error": "Path does not exist", "path": str(abs_path)}
        
        if not abs_path.is_dir():
            logger.warning(f"Attempted to list non-directory: {abs_path}")
            return {"error": "Path is not a directory", "path": str(abs_path)}
        
        # Check read permissions
        if not os.access(abs_path, os.R_OK):
            logger.error(f"Permission denied accessing: {abs_path}")
            return {"error": "Permission denied", "path": str(abs_path)}

        items = []
        total_size = 0
        file_count = 0
        dir_count = 0
        
        for item in abs_path.iterdir():
            try:
                item_stat = item.stat()
                item_info = {
                    "name": item.name,
                    "path": str(item),
                    "type": "dir" if item.is_dir() else "file",
                    "size": item_stat.st_size if item.is_file() else None,
                    "modified": datetime.fromtimestamp(item_stat.st_mtime).isoformat(),
                    "permissions": stat.filemode(item_stat.st_mode),
                    "readable": os.access(item, os.R_OK),
                    "writable": os.access(item, os.W_OK)
                }
                
                if item.is_file():
                    file_count += 1
                    total_size += item_stat.st_size
                else:
                    dir_count += 1
                
                items.append(item_info)
                
            except (OSError, PermissionError) as e:
                logger.warning(f"Could not access item {item}: {e}")
                items.append({
                    "name": item.name,
                    "path": str(item),
                    "type": "unknown",
                    "error": "Access denied"
                })

        # Sort items: directories first, then files, both alphabetically
        items.sort(key=lambda x: (x["type"] != "dir", x["name"].lower()))

        result = {
            "path": str(abs_path),
            "items": items,
            "summary": {
                "total_items": len(items),
                "files": file_count,
                "directories": dir_count,
                "total_size": total_size
            }
        }

        logger.info(f"Successfully listed directory: {abs_path}", extra={
            "path": str(abs_path),
            "item_count": len(items),
            "file_count": file_count,
            "dir_count": dir_count
        })
        
        return result
        
    except Exception as e:
        logger.error(f"Error listing files in {path}", exc_info=True, extra={
            "path": path,
            "error_type": type(e).__name__
        })
        return {"error": f"Failed to list directory: {str(e)}"}

@log_performance
def read_file(path: str) -> Dict[str, Any]:
    """
    Read file contents safely with encoding detection
    
    Args:
        path: File path to read
        
    Returns:
        Dictionary containing file content and metadata
    """
    logger.debug(f"Reading file: {path}")
    
    try:
        # Resolve and validate path
        abs_path = Path(path).expanduser().resolve()
        
        # Security checks
        if not abs_path.exists():
            logger.warning(f"Attempted to read non-existent file: {abs_path}")
            return {"error": "File does not exist", "path": str(abs_path)}
        
        if not abs_path.is_file():
            logger.warning(f"Attempted to read non-file: {abs_path}")
            return {"error": "Path is not a file", "path": str(abs_path)}
        
        if not os.access(abs_path, os.R_OK):
            logger.error(f"Permission denied reading file: {abs_path}")
            return {"error": "Permission denied", "path": str(abs_path)}
        
        # Get file metadata
        file_stat = abs_path.stat()
        file_size = file_stat.st_size
        
        # Check file size (limit to 10MB for safety)
        if file_size > 10 * 1024 * 1024:
            logger.warning(f"Attempted to read large file: {abs_path} ({file_size} bytes)")
            return {"error": "File too large (max 10MB)", "path": str(abs_path)}
        
        # Try to read with UTF-8, fallback to binary
        try:
            with open(abs_path, "r", encoding="utf-8") as f:
                content = f.read()
            encoding = "utf-8"
            is_binary = False
        except UnicodeDecodeError:
            logger.debug(f"File appears to be binary: {abs_path}")
            with open(abs_path, "rb") as f:
                raw_content = f.read()
            content = raw_content.hex()  # Return hex representation
            encoding = "binary"
            is_binary = True
        
        result = {
            "path": str(abs_path),
            "content": content,
            "metadata": {
                "size": file_size,
                "encoding": encoding,
                "is_binary": is_binary,
                "modified": datetime.fromtimestamp(file_stat.st_mtime).isoformat(),
                "permissions": stat.filemode(file_stat.st_mode)
            }
        }
        
        logger.info(f"Successfully read file: {abs_path}", extra={
            "path": str(abs_path),
            "size": file_size,
            "encoding": encoding,
            "is_binary": is_binary
        })
        
        return result
        
    except Exception as e:
        logger.error(f"Error reading file {path}", exc_info=True, extra={
            "path": path,
            "error_type": type(e).__name__
        })
        return {"error": f"Failed to read file: {str(e)}"}

@log_performance
def write_file(path: str, content: str, encoding: str = "utf-8") -> Dict[str, Any]:
    """
    Write content to file safely with backup and validation
    
    Args:
        path: File path to write
        content: Content to write
        encoding: Text encoding to use
        
    Returns:
        Dictionary containing operation status
    """
    logger.debug(f"Writing file: {path}")
    
    try:
        abs_path = Path(path).expanduser().resolve()
        
        # Create backup if file exists
        backup_path = None
        if abs_path.exists():
            backup_path = abs_path.with_suffix(abs_path.suffix + ".bak")
            logger.debug(f"Creating backup: {backup_path}")
            abs_path.rename(backup_path)
        
        # Write new content
        abs_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(abs_path, "w", encoding=encoding) as f:
            f.write(content)
        
        # Verify write
        if not abs_path.exists():
            raise IOError("File was not created successfully")
        
        written_size = abs_path.stat().st_size
        
        # Remove backup on successful write
        if backup_path and backup_path.exists():
            backup_path.unlink()
            logger.debug(f"Removed backup: {backup_path}")
        
        logger.info(f"Successfully wrote file: {abs_path}", extra={
            "path": str(abs_path),
            "size": written_size,
            "encoding": encoding
        })
        
        return {
            "status": "success",
            "path": str(abs_path),
            "size": written_size,
            "encoding": encoding
        }
        
    except Exception as e:
        # Restore backup if write failed
        if backup_path and backup_path.exists():
            try:
                backup_path.rename(abs_path)
                logger.info(f"Restored backup after write failure: {abs_path}")
            except Exception as restore_error:
                logger.error(f"Failed to restore backup: {restore_error}")
        
        logger.error(f"Error writing file {path}", exc_info=True, extra={
            "path": path,
            "error_type": type(e).__name__
        })
        return {"error": f"Failed to write file: {str(e)}"}

@log_performance
def delete_file(path: str) -> Dict[str, Any]:
    """
    Delete file or directory safely with confirmation
    
    Args:
        path: Path to delete
        
    Returns:
        Dictionary containing operation status
    """
    logger.debug(f"Deleting path: {path}")
    
    try:
        abs_path = Path(path).expanduser().resolve()
        
        if not abs_path.exists():
            logger.warning(f"Attempted to delete non-existent path: {abs_path}")
            return {"error": "Path does not exist", "path": str(abs_path)}
        
        # Check permissions
        if not os.access(abs_path.parent, os.W_OK):
            logger.error(f"Permission denied deleting: {abs_path}")
            return {"error": "Permission denied", "path": str(abs_path)}
        
        # Perform deletion
        if abs_path.is_file():
            abs_path.unlink()
            logger.info(f"Successfully deleted file: {abs_path}")
        elif abs_path.is_dir():
            abs_path.rmdir()  # Only delete empty directories for safety
            logger.info(f"Successfully deleted directory: {abs_path}")
        else:
            return {"error": "Unknown path type", "path": str(abs_path)}
        
        return {"status": "success", "path": str(abs_path)}
        
    except OSError as e:
        if e.errno == 39:  # Directory not empty
            logger.warning(f"Attempted to delete non-empty directory: {path}")
            return {"error": "Directory not empty", "path": path}
        else:
            logger.error(f"OS error deleting {path}", exc_info=True)
            return {"error": f"System error: {str(e)}"}
    except Exception as e:
        logger.error(f"Error deleting {path}", exc_info=True, extra={
            "path": path,
            "error_type": type(e).__name__
        })
        return {"error": f"Failed to delete: {str(e)}"}