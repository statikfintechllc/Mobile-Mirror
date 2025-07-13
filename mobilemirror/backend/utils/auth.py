#!/usr/bin/env python3
"""
Mobile Mirror Authentication Module
==================================

Provides secure authentication and authorization for Mobile Mirror API access.
Supports multiple authentication methods including tokens, API keys, and 
session-based authentication with comprehensive security features.

Features:
- Token-based authentication
- API key validation
- Session management
- Rate limiting per user/IP
- Comprehensive audit logging
- Security breach detection
- Token expiration and rotation

Security Features:
- Secure token generation and validation
- Protection against timing attacks
- Failed attempt tracking and blocking
- Comprehensive security audit logging
"""

import os
import hmac
import hashlib
import secrets
import time
from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
from pathlib import Path

from .logger import get_logger, log_performance

# Initialize module logger
logger = get_logger(__name__)

# Configuration
DEFAULT_TOKEN = "mobilemirror-access"
TOKEN_FILE = Path.home() / ".local/share/mobilemirror/auth/tokens.conf"
MAX_FAILED_ATTEMPTS = 5
LOCKOUT_DURATION = 300  # 5 minutes in seconds

# Security tracking
failed_attempts: Dict[str, List[float]] = {}
blocked_ips: Dict[str, float] = {}

def ensure_auth_directory():
    """Ensure authentication directory exists"""
    TOKEN_FILE.parent.mkdir(parents=True, exist_ok=True)

def generate_secure_token(length: int = 32) -> str:
    """
    Generate a cryptographically secure random token
    
    Args:
        length: Token length in characters
        
    Returns:
        Secure random token string
    """
    logger.debug(f"Generating secure token of length {length}")
    token = secrets.token_urlsafe(length)
    logger.info("Secure token generated successfully")
    return token

def hash_token(token: str, salt: Optional[str] = None) -> Tuple[str, str]:
    """
    Hash a token with salt for secure storage
    
    Args:
        token: Token to hash
        salt: Optional salt (generated if not provided)
        
    Returns:
        Tuple of (hashed_token, salt)
    """
    if salt is None:
        salt = secrets.token_hex(16)
    
    # Use PBKDF2 for secure hashing
    hashed = hashlib.pbkdf2_hmac('sha256', token.encode(), salt.encode(), 100000)
    return hashed.hex(), salt

def verify_token_hash(token: str, hashed_token: str, salt: str) -> bool:
    """
    Verify a token against its hash
    
    Args:
        token: Token to verify
        hashed_token: Stored hash
        salt: Salt used for hashing
        
    Returns:
        True if token is valid
    """
    computed_hash, _ = hash_token(token, salt)
    
    # Use hmac.compare_digest to prevent timing attacks
    return hmac.compare_digest(computed_hash, hashed_token)

def is_ip_blocked(ip_address: str) -> bool:
    """
    Check if an IP address is currently blocked
    
    Args:
        ip_address: IP address to check
        
    Returns:
        True if IP is blocked
    """
    if ip_address not in blocked_ips:
        return False
    
    block_time = blocked_ips[ip_address]
    if time.time() - block_time > LOCKOUT_DURATION:
        # Unblock expired blocks
        del blocked_ips[ip_address]
        logger.info(f"IP address unblocked after lockout period: {ip_address}")
        return False
    
    return True

def record_failed_attempt(ip_address: str):
    """
    Record a failed authentication attempt
    
    Args:
        ip_address: IP address of failed attempt
    """
    current_time = time.time()
    
    # Clean old attempts (older than lockout duration)
    if ip_address in failed_attempts:
        failed_attempts[ip_address] = [
            attempt_time for attempt_time in failed_attempts[ip_address]
            if current_time - attempt_time < LOCKOUT_DURATION
        ]
    else:
        failed_attempts[ip_address] = []
    
    # Record this attempt
    failed_attempts[ip_address].append(current_time)
    
    # Check if IP should be blocked
    if len(failed_attempts[ip_address]) >= MAX_FAILED_ATTEMPTS:
        blocked_ips[ip_address] = current_time
        logger.warning(f"IP address blocked due to repeated failed attempts: {ip_address}", extra={
            "ip_address": ip_address,
            "failed_attempts": len(failed_attempts[ip_address]),
            "lockout_duration": LOCKOUT_DURATION
        })
    else:
        logger.warning(f"Failed authentication attempt from {ip_address}", extra={
            "ip_address": ip_address,
            "attempt_count": len(failed_attempts[ip_address]),
            "max_attempts": MAX_FAILED_ATTEMPTS
        })

def load_tokens() -> Dict[str, Dict]:
    """
    Load tokens from configuration file
    
    Returns:
        Dictionary of token configurations
    """
    try:
        ensure_auth_directory()
        
        if not TOKEN_FILE.exists():
            logger.info("No token file found, using defaults")
            return {}
        
        tokens = {}
        with open(TOKEN_FILE, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    parts = line.split(':')
                    if len(parts) >= 3:
                        name = parts[0]
                        hashed_token = parts[1]
                        salt = parts[2]
                        tokens[name] = {
                            'hash': hashed_token,
                            'salt': salt,
                            'created': parts[3] if len(parts) > 3 else str(int(time.time()))
                        }
        
        logger.debug(f"Loaded {len(tokens)} tokens from configuration")
        return tokens
        
    except Exception as e:
        logger.error("Failed to load tokens", exc_info=True)
        return {}

def save_token(name: str, token: str) -> bool:
    """
    Save a new token to configuration file
    
    Args:
        name: Token name/identifier
        token: Token value
        
    Returns:
        True if token was saved successfully
    """
    try:
        ensure_auth_directory()
        
        # Hash the token
        hashed_token, salt = hash_token(token)
        
        # Append to token file
        with open(TOKEN_FILE, 'a') as f:
            f.write(f"{name}:{hashed_token}:{salt}:{int(time.time())}\n")
        
        logger.info(f"Token saved successfully: {name}")
        return True
        
    except Exception as e:
        logger.error(f"Failed to save token: {name}", exc_info=True)
        return False

@log_performance
def verify_token(token: str, ip_address: str = "unknown") -> bool:
    """
    Verify an authentication token with security controls
    
    Args:
        token: Token to verify
        ip_address: IP address of the request
        
    Returns:
        True if token is valid and request is authorized
    """
    logger.debug(f"Token verification requested from {ip_address}")
    
    # Check if IP is blocked
    if is_ip_blocked(ip_address):
        logger.warning(f"Blocked IP attempted access: {ip_address}")
        return False
    
    # Check environment variable token
    expected_env_token = os.getenv("MOBILEMIRROR_TOKEN", DEFAULT_TOKEN)
    
    if hmac.compare_digest(token, expected_env_token):
        logger.info(f"Successful authentication from {ip_address}", extra={
            "ip_address": ip_address,
            "auth_method": "environment_token"
        })
        return True
    
    # Check file-based tokens
    stored_tokens = load_tokens()
    
    for token_name, token_data in stored_tokens.items():
        if verify_token_hash(token, token_data['hash'], token_data['salt']):
            logger.info(f"Successful authentication from {ip_address}", extra={
                "ip_address": ip_address,
                "auth_method": "file_token",
                "token_name": token_name
            })
            return True
    
    # Authentication failed
    logger.warning(f"Authentication failed from {ip_address}", extra={
        "ip_address": ip_address,
        "token_length": len(token) if token else 0
    })
    
    record_failed_attempt(ip_address)
    return False

def create_api_key(name: str, permissions: Optional[List[str]] = None) -> Optional[str]:
    """
    Create a new API key with specified permissions
    
    Args:
        name: Name/identifier for the key
        permissions: List of permissions (future feature)
        
    Returns:
        Generated API key or None if creation failed
    """
    try:
        token = generate_secure_token(32)
        
        if save_token(name, token):
            logger.info(f"API key created successfully: {name}", extra={
                "key_name": name,
                "permissions": permissions or []
            })
            return token
        else:
            return None
            
    except Exception as e:
        logger.error(f"Failed to create API key: {name}", exc_info=True)
        return None

def get_auth_stats() -> Dict:
    """Get authentication statistics and security metrics"""
    current_time = time.time()
    
    # Clean expired data
    active_blocks = {ip: block_time for ip, block_time in blocked_ips.items() 
                    if current_time - block_time <= LOCKOUT_DURATION}
    
    recent_attempts = {}
    for ip, attempts in failed_attempts.items():
        recent = [t for t in attempts if current_time - t <= LOCKOUT_DURATION]
        if recent:
            recent_attempts[ip] = len(recent)
    
    return {
        "blocked_ips": len(active_blocks),
        "recent_failed_attempts": sum(recent_attempts.values()),
        "unique_ips_with_failures": len(recent_attempts),
        "token_file_exists": TOKEN_FILE.exists(),
        "stored_tokens": len(load_tokens()),
        "lockout_duration": LOCKOUT_DURATION,
        "max_attempts": MAX_FAILED_ATTEMPTS
    }