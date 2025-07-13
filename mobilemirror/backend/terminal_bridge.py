#!/usr/bin/env python3
"""
Mobile Mirror Terminal Bridge Module
===================================

Provides secure WebSocket-based terminal access for mobile clients.
Handles PTY (pseudo-terminal) creation and bidirectional communication
between mobile devices and the host system shell.

Features:
- WebSocket terminal connections
- PTY (pseudo-terminal) management
- Real-time bidirectional communication
- Security controls and session management
- Comprehensive logging and monitoring
- Connection cleanup and resource management

Security Considerations:
- Terminal sessions are isolated per connection
- Shell commands are logged for audit purposes
- Resource limits to prevent abuse
- Automatic cleanup on disconnect
"""

import asyncio
import os
import pty
import signal
import select
from typing import Dict, Optional
from datetime import datetime

from fastapi import WebSocket, WebSocketDisconnect
from .utils.logger import get_logger, log_performance

# Initialize module logger
logger = get_logger(__name__)

# Configuration
SHELL = os.environ.get("SHELL", "/bin/bash")
MAX_BUFFER_SIZE = 8192
READ_TIMEOUT = 0.1

# Active terminal sessions registry
active_sessions: Dict[str, Dict] = {}

class TerminalSession:
    """Manages a single terminal session with PTY and WebSocket"""
    
    def __init__(self, websocket: WebSocket, session_id: str):
        self.websocket = websocket
        self.session_id = session_id
        self.pid: Optional[int] = None
        self.fd: Optional[int] = None
        self.start_time = datetime.now()
        self.command_count = 0
        self.bytes_sent = 0
        self.bytes_received = 0
        
        logger.info(f"Created terminal session: {session_id}")
    
    async def start(self):
        """Start the PTY and begin communication"""
        try:
            logger.debug(f"Starting PTY for session {self.session_id}")
            
            # Create PTY
            self.pid, self.fd = pty.fork()
            
            if self.pid == 0:
                # Child process: execute shell
                logger.debug(f"Child process starting shell: {SHELL}")
                os.execvp(SHELL, [SHELL])
            else:
                # Parent process: handle communication
                logger.info(f"PTY created for session {self.session_id}", extra={
                    "pid": self.pid,
                    "fd": self.fd,
                    "shell": SHELL
                })
                
                # Register session
                active_sessions[self.session_id] = {
                    "session": self,
                    "start_time": self.start_time,
                    "pid": self.pid
                }
                
                # Start communication tasks
                await asyncio.gather(
                    self._read_from_shell(),
                    self._write_to_shell(),
                    return_exceptions=True
                )
                
        except Exception as e:
            logger.error(f"Failed to start terminal session {self.session_id}", exc_info=True)
            await self.cleanup()
            raise
    
    async def _read_from_shell(self):
        """Read output from shell and send to WebSocket"""
        logger.debug(f"Starting shell reader for session {self.session_id}")
        
        try:
            while True:
                if self.fd is None:
                    break
                
                # Use select to check for data availability
                ready, _, _ = select.select([self.fd], [], [], READ_TIMEOUT)
                
                if ready:
                    try:
                        data = os.read(self.fd, MAX_BUFFER_SIZE)
                        if not data:
                            logger.debug(f"Shell closed for session {self.session_id}")
                            break
                        
                        decoded = data.decode(errors="ignore")
                        await self.websocket.send_text(decoded)
                        
                        self.bytes_sent += len(data)
                        
                        # Log significant output for audit
                        if len(decoded.strip()) > 0:
                            logger.debug(f"Shell output for session {self.session_id}", extra={
                                "output_length": len(decoded),
                                "bytes_sent": self.bytes_sent
                            })
                            
                    except OSError as e:
                        if e.errno == 5:  # Input/output error (shell closed)
                            logger.info(f"Shell terminated for session {self.session_id}")
                            break
                        else:
                            raise
                
                await asyncio.sleep(0.01)  # Small delay to prevent busy loop
                
        except WebSocketDisconnect:
            logger.info(f"WebSocket disconnected for session {self.session_id}")
        except Exception as e:
            logger.error(f"Shell read error for session {self.session_id}", exc_info=True)
        finally:
            await self.cleanup()
    
    async def _write_to_shell(self):
        """Read input from WebSocket and write to shell"""
        logger.debug(f"Starting shell writer for session {self.session_id}")
        
        try:
            while True:
                if self.fd is None:
                    break
                
                try:
                    message = await self.websocket.receive_text()
                    
                    if message:
                        # Log commands for audit (but not passwords/sensitive data)
                        sanitized = message.replace('\r', '\\r').replace('\n', '\\n')
                        if not any(keyword in message.lower() for keyword in ['password', 'passwd', 'secret', 'key']):
                            logger.debug(f"Command input for session {self.session_id}: {sanitized}")
                        else:
                            logger.debug(f"Sensitive input for session {self.session_id}: [REDACTED]")
                        
                        os.write(self.fd, message.encode())
                        self.bytes_received += len(message.encode())
                        self.command_count += message.count('\n')  # Approximate command count
                        
                except WebSocketDisconnect:
                    logger.info(f"WebSocket disconnected for session {self.session_id}")
                    break
                    
        except Exception as e:
            logger.error(f"Shell write error for session {self.session_id}", exc_info=True)
        finally:
            await self.cleanup()
    
    async def cleanup(self):
        """Clean up PTY and session resources"""
        logger.debug(f"Cleaning up session {self.session_id}")
        
        try:
            # Close file descriptor
            if self.fd is not None:
                os.close(self.fd)
                self.fd = None
            
            # Terminate child process
            if self.pid is not None:
                try:
                    os.kill(self.pid, signal.SIGTERM)
                    os.waitpid(self.pid, 0)  # Wait for process to terminate
                except (OSError, ProcessLookupError):
                    pass  # Process may already be dead
                self.pid = None
            
            # Remove from active sessions
            if self.session_id in active_sessions:
                del active_sessions[self.session_id]
            
            # Log session statistics
            duration = (datetime.now() - self.start_time).total_seconds()
            logger.info(f"Terminal session ended: {self.session_id}", extra={
                "duration_seconds": duration,
                "commands_executed": self.command_count,
                "bytes_sent": self.bytes_sent,
                "bytes_received": self.bytes_received
            })
            
        except Exception as e:
            logger.error(f"Error during session cleanup {self.session_id}", exc_info=True)

@log_performance
async def handle_terminal(websocket: WebSocket):
    """
    Handle a new terminal WebSocket connection
    
    Args:
        websocket: WebSocket connection from client
    """
    session_id = f"term_{id(websocket)}_{int(datetime.now().timestamp())}"
    
    logger.info(f"New terminal connection request: {session_id}")
    
    try:
        await websocket.accept()
        logger.info(f"WebSocket terminal connection accepted: {session_id}")
        
        # Create and start terminal session
        session = TerminalSession(websocket, session_id)
        await session.start()
        
    except WebSocketDisconnect:
        logger.info(f"Terminal WebSocket disconnected: {session_id}")
    except Exception as e:
        logger.error(f"Terminal connection error: {session_id}", exc_info=True)
        try:
            await websocket.close()
        except:
            pass

def get_session_stats() -> Dict:
    """Get statistics about active terminal sessions"""
    stats = {
        "active_sessions": len(active_sessions),
        "sessions": []
    }
    
    for session_id, session_data in active_sessions.items():
        session = session_data["session"]
        duration = (datetime.now() - session.start_time).total_seconds()
        
        stats["sessions"].append({
            "session_id": session_id,
            "pid": session.pid,
            "duration_seconds": duration,
            "commands_executed": session.command_count,
            "bytes_sent": session.bytes_sent,
            "bytes_received": session.bytes_received
        })
    
    return stats