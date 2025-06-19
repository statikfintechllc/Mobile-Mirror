#!/usr/bin/env python3
# terminal_bridge.py — Handles pty ↔ WebSocket shell for TouchCore

import asyncio
import os
import pty
import subprocess
import shlex
from fastapi import WebSocket
from logger import log_event

SHELL = os.environ.get("SHELL", "/bin/bash")

async def handle_terminal(websocket: WebSocket):
    await websocket.accept()
    log_event("WebSocket shell connection opened.")

    pid, fd = pty.fork()
    if pid == 0:
        os.execvp(SHELL, [SHELL])  # Child: start shell
    else:
        loop = asyncio.get_event_loop()

        async def read_from_shell():
            try:
                while True:
                    data = os.read(fd, 1024)
                    await websocket.send_text(data.decode())
            except Exception as e:
                log_event(f"[WS Shell Read Error] {e}")
                await websocket.close()

        async def write_to_shell():
            try:
                while True:
                    data = await websocket.receive_text()
                    os.write(fd, data.encode())
            except Exception as e:
                log_event(f"[WS Shell Write Error] {e}")
                await websocket.close()

        await asyncio.gather(read_from_shell(), write_to_shell())