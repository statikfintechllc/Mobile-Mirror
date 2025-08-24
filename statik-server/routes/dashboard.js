const express = require('express');
const router = express.Router();
const path = require('path');
const fs = require('fs');

// Serve dashboard
router.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '../dashboard/index.html'));
});

// API endpoints
router.get('/api/status', (req, res) => {
    res.json({
        vscode: { status: 'running', port: 8080 },
        tailscale: { status: 'stopped' },
        https: { enabled: true },
        uptime: process.uptime()
    });
});

router.get('/api/tailscale/status', (req, res) => {
    // Simulate tailscale status
    res.json({
        status: 'stopped',
        ip: null,
        hostname: require('os').hostname()
    });
});

router.post('/api/tailscale/connect', (req, res) => {
    // Simulate tailscale connection
    res.json({ success: true, message: 'Connection initiated' });
});

router.post('/api/tailscale/disconnect', (req, res) => {
    // Simulate tailscale disconnection
    res.json({ success: true, message: 'Disconnected' });
});

module.exports = router;
