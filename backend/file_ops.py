#!/usr/bin/env python3
# file_ops.py — Local file system browse & edit module for TouchCore

import os
from pathlib import Path
from logger import log_event

def list_files(path="."):
    try:
        abs_path = Path(path).expanduser().resolve()
        if not abs_path.exists():
            return {"error": "Path does not exist."}

        items = []
        for item in abs_path.iterdir():
            items.append({
                "name": item.name,
                "path": str(item),
                "type": "dir" if item.is_dir() else "file",
                "size": item.stat().st_size if item.is_file() else None
            })

        log_event(f"Listed files in {abs_path}")
        return {"path": str(abs_path), "items": items}
    except Exception as e:
        log_event(f"[ERR] list_files: {e}")
        return {"error": str(e)}

def read_file(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        log_event(f"Opened file: {path}")
        return {"path": path, "content": content}
    except Exception as e:
        log_event(f"[ERR] read_file: {e}")
        return {"error": str(e)}

def write_file(path, content):
    try:
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        log_event(f"Saved file: {path}")
        return {"status": "success", "path": path}
    except Exception as e:
        log_event(f"[ERR] write_file: {e}")
        return {"error": str(e)}