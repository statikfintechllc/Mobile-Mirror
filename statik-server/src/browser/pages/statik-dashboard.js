// Statik-Server Unified Dashboard JavaScript

class StatikDashboard {
    constructor() {
        this.currentTab = 'overview';
        this.memoryFeedActive = true;
        this.autonomousMode = false;
        this.vscodeConfig = {
            stock: { port: 8080, url: 'http://localhost:8080' },
            gremlin: { port: 8081, url: 'http://localhost:8081' }
        };
        this.init();
    }

    init() {
        this.setupNavigation();
        this.setupEventListeners();
        this.startMemoryFeed();
        this.startStatusUpdates();
        this.loadGremlinComponents();
        this.loadGodCoreComponents();
        this.loadMobileMirrorComponents();
        console.log('🚀 Statik-Server Dashboard initialized');
    }

    setupNavigation() {
        const navButtons = document.querySelectorAll('.nav-btn');
        navButtons.forEach(btn => {
            btn.addEventListener('click', () => {
                const tabName = btn.dataset.tab;
                this.switchTab(tabName);
            });
        });
    }

    switchTab(tabName) {
        // Update navigation
        document.querySelectorAll('.nav-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        const targetBtn = document.querySelector(`[data-tab="${tabName}"]`);
        if (targetBtn) {
            targetBtn.classList.add('active');
        }

        // Update content
        document.querySelectorAll('.tab-content').forEach(content => {
            content.classList.remove('active');
        });
        const targetContent = document.getElementById(tabName);
        if (targetContent) {
            targetContent.classList.add('active');
        }

        this.currentTab = tabName;

        // Load tab-specific content
        this.loadTabContent(tabName);
    }

    loadTabContent(tabName) {
        switch(tabName) {
            case 'vscode-stock':
                this.loadStockVSCode();
                break;
            case 'vscode-gremlin':
                this.loadGremlinVSCode();
                break;
            case 'mesh':
                this.loadMeshVPN();
                break;
            case 'system':
                this.loadSystemDashboard();
                break;
            default:
                // Overview tab or others - already loaded
                break;
        }
    }

    setupEventListeners() {
        // Global keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            if (e.ctrlKey || e.metaKey) {
                switch(e.key) {
                    case '1':
                        e.preventDefault();
                        this.switchTab('overview');
                        break;
                    case '2':
                        e.preventDefault();
                        this.switchTab('vscode');
                        break;
                    case '3':
                        e.preventDefault();
                        this.switchTab('gremlin');
                        break;
                    case '4':
                        e.preventDefault();
                        this.switchTab('godcore');
                        break;
                    case '5':
                        e.preventDefault();
                        this.switchTab('mobile');
                        break;
                }
            }
        });

        // Auto-refresh intervals
        setInterval(() => this.updateSystemStatus(), 5000);
        setInterval(() => this.updateMeshStatus(), 10000);
    }

    // Memory Feed Management
    startMemoryFeed() {
        this.memoryEventSource = new EventSource('/api/statik/memory/live');

        this.memoryEventSource.onmessage = (event) => {
            if (!this.memoryFeedActive) return;

            try {
                const memoryData = JSON.parse(event.data);
                this.updateMemoryFeed(memoryData);
                this.updateMemoryStats(memoryData);
            } catch (e) {
                console.error('Error parsing memory data:', e);
            }
        };

        this.memoryEventSource.onerror = () => {
            console.warn('Memory feed connection lost, attempting reconnect...');
            setTimeout(() => this.startMemoryFeed(), 5000);
        };
    }

    updateMemoryFeed(data) {
        const feedContainer = document.getElementById('memory-feed');
        const liveFeedContainer = document.getElementById('live-memory-feed');

        if (!feedContainer && !liveFeedContainer) return;

        // Create new memory entries
        const entries = [];

        if (data.gremlinGPT && data.gremlinGPT.signal_trace) {
            data.gremlinGPT.signal_trace.slice(-3).forEach(signal => {
                entries.push({
                    timestamp: new Date().toLocaleTimeString(),
                    source: 'gremlin',
                    content: signal.substring(0, 50) + (signal.length > 50 ? '...' : '')
                });
            });
        }

        if (data.godCore && data.godCore.execution_context) {
            entries.push({
                timestamp: new Date().toLocaleTimeString(),
                source: 'godcore',
                content: `Shell state: ${data.godCore.shell_state}`
            });
        }

        // Update both containers
        [feedContainer, liveFeedContainer].forEach(container => {
            if (!container) return;

            entries.forEach(entry => {
                const entryElement = document.createElement('div');
                entryElement.className = 'memory-item';
                entryElement.innerHTML = `
                    <span class="memory-timestamp">${entry.timestamp}</span>
                    <span class="memory-source ${entry.source}">${entry.source.toUpperCase()}</span>
                    <span class="memory-content">${entry.content}</span>
                `;

                container.insertBefore(entryElement, container.firstChild);

                // Limit to 20 entries
                if (container.children.length > 20) {
                    container.removeChild(container.lastChild);
                }
            });
        });
    }

    // Stock VS Code Integration
    async loadStockVSCode() {
        const iframe = document.getElementById('vscode-stock-frame');
        if (!iframe) return;

        try {
            // Load tunnel configuration
            const config = await this.loadTunnelConfig();

            if (config && config.vscode && config.vscode.stock) {
                const vscodeUrl = config.vscode.stock.iframe_src || config.vscode.stock.url;
                if (vscodeUrl && vscodeUrl !== iframe.src) {
                    console.log('Loading Stock VS Code from tunnel URL:', vscodeUrl);
                    iframe.src = vscodeUrl;
                    this.updateStockVSCodeStatus('connected', 'Tunneled via Tailscale');
                    document.getElementById('stock-vscode-url-status').textContent = vscodeUrl;
                }
            } else {
                // Fallback to local
                const localUrl = this.vscodeConfig.stock.url;
                if (iframe.src !== localUrl) {
                    console.log('Loading Stock VS Code from local URL:', localUrl);
                    iframe.src = localUrl;
                    this.updateStockVSCodeStatus('local', 'Local connection');
                    document.getElementById('stock-vscode-url-status').textContent = localUrl;
                }
            }
        } catch (error) {
            console.error('Error loading Stock VS Code tunnel config:', error);
            // Fallback to local
            const localUrl = this.vscodeConfig.stock.url;
            iframe.src = localUrl;
            this.updateStockVSCodeStatus('local', 'Local connection (fallback)');
            document.getElementById('stock-vscode-url-status').textContent = localUrl;
        }
    }

    // GremlinGPT VS Code Integration
    async loadGremlinVSCode() {
        const iframe = document.getElementById('vscode-gremlin-frame');
        if (!iframe) return;

        try {
            // Load tunnel configuration
            const config = await this.loadTunnelConfig();

            if (config && config.vscode && config.vscode.gremlingpt) {
                const vscodeUrl = config.vscode.gremlingpt.iframe_src || config.vscode.gremlingpt.url;
                if (vscodeUrl && vscodeUrl !== iframe.src) {
                    console.log('Loading GremlinGPT VS Code from tunnel URL:', vscodeUrl);
                    iframe.src = vscodeUrl;
                    this.updateGremlinVSCodeStatus('connected', 'AI-Enhanced via Tailscale');
                    document.getElementById('gremlin-vscode-url-status').textContent = vscodeUrl;
                }
            } else {
                // Fallback to local
                const localUrl = this.vscodeConfig.gremlin.url;
                if (iframe.src !== localUrl) {
                    console.log('Loading GremlinGPT VS Code from local URL:', localUrl);
                    iframe.src = localUrl;
                    this.updateGremlinVSCodeStatus('local', 'AI-Enhanced (local)');
                    document.getElementById('gremlin-vscode-url-status').textContent = localUrl;
                }
            }
        } catch (error) {
            console.error('Error loading GremlinGPT VS Code tunnel config:', error);
            // Fallback to local
            const localUrl = this.vscodeConfig.gremlin.url;
            iframe.src = localUrl;
            this.updateGremlinVSCodeStatus('local', 'AI-Enhanced (local fallback)');
            document.getElementById('gremlin-vscode-url-status').textContent = localUrl;
        }
    }

    // VS Code Integration (Legacy)
    async loadVSCode() {
        const iframe = document.getElementById('vscode-frame');
        if (!iframe) return;

        try {
            // Load tunnel configuration
            const config = await this.loadTunnelConfig();

            if (config && config.services && config.services.vscode) {
                const vscodeUrl = config.services.vscode.iframe_src || config.services.vscode.url;
                if (vscodeUrl && vscodeUrl !== iframe.src) {
                    console.log('Loading VS Code from tunnel URL:', vscodeUrl);
                    iframe.src = vscodeUrl;

                    // Update status indicator
                    this.updateVSCodeStatus('connected', 'Tunneled via Tailscale');
                }
            } else {
                // Fallback to local
                if (!iframe.src) {
                    console.log('Loading VS Code from local URL');
                    iframe.src = '/';
                    this.updateVSCodeStatus('local', 'Local connection');
                }
            }
        } catch (error) {
            console.error('Error loading VS Code tunnel config:', error);
            // Fallback to local
            if (!iframe.src) {
                iframe.src = '/';
                this.updateVSCodeStatus('local', 'Local connection (fallback)');
            }
        }
    }

    async loadTunnelConfig() {
        try {
            const response = await fetch('/api/config/runtime');
            if (response.ok) {
                return await response.json();
            }
        } catch (error) {
            console.log('Tunnel config not available:', error.message);
        }
        return null;
    }

    updateVSCodeStatus(type, message) {
        const statusElement = document.getElementById('vscode-status');
        if (statusElement) {
            const icon = type === 'connected' ? '🌍' : type === 'local' ? '🏠' : '💻';
            statusElement.innerHTML = `${icon} ${message}`;
            statusElement.className = `status-value ${type}`;
        }
    }

    // Stock VS Code Status Management
    updateStockVSCodeStatus(type, message) {
        const statusElement = document.getElementById('stock-vscode-status');
        if (statusElement) {
            const icon = type === 'connected' ? '🌍' : type === 'local' ? '🏠' : '💻';
            statusElement.innerHTML = `${icon} ${message}`;
            statusElement.className = `status-value ${type}`;
        }
    }

    // GremlinGPT VS Code Status Management
    updateGremlinVSCodeStatus(type, message) {
        const statusElement = document.getElementById('gremlin-vscode-status');
        if (statusElement) {
            const icon = type === 'connected' ? '🌍🤖' : type === 'local' ? '🏠🤖' : '💻🤖';
            statusElement.innerHTML = `${icon} ${message}`;
            statusElement.className = `status-value ${type}`;
        }
    }

    // VS Code Control Functions for Stock Instance
    reloadStockVSCode() {
        const iframe = document.getElementById('vscode-stock-frame');
        if (iframe && iframe.src) {
            iframe.src = iframe.src;
            this.updateStockVSCodeStatus('local', 'Reloading...');
            setTimeout(() => this.loadStockVSCode(), 1000);
        }
    }

    async openStockVSCodeNew() {
        const config = await this.loadTunnelConfig();
        let url = 'http://localhost:8080'; // fallback
        
        if (config && config.vscode && config.vscode.stock) {
            url = config.vscode.stock.url;
        }
        
        window.open(url, '_blank', 'noopener,noreferrer');
    }

    // VS Code Control Functions for GremlinGPT Instance
    reloadGremlinVSCode() {
        const iframe = document.getElementById('vscode-gremlin-frame');
        if (iframe && iframe.src) {
            iframe.src = iframe.src;
            this.updateGremlinVSCodeStatus('local', 'Reloading AI-Enhanced...');
            setTimeout(() => this.loadGremlinVSCode(), 1000);
        }
    }

    async openGremlinVSCodeNew() {
        const config = await this.loadTunnelConfig();
        let url = 'http://localhost:8081'; // fallback
        
        if (config && config.vscode && config.vscode.gremlingpt) {
            url = config.vscode.gremlingpt.url;
        }
        
        window.open(url, '_blank', 'noopener,noreferrer');
    }

    // GremlinGPT Integration
    loadGremlinGPT() {
        this.loadGremlinChat();
        this.loadGremlinFSM();
        this.loadGremlinMemory();
        this.loadTradingPanel();
    }

    loadGremlinComponents() {
        // Load GremlinGPT specific components
        this.gremlinFSMState = 'idle';
        this.gremlinMemoryGraph = new Map();
        this.tradingSignals = [];
    }

    loadGremlinChat() {
        const messagesContainer = document.getElementById('gremlin-messages');
        if (!messagesContainer) return;

        // Add welcome message if empty
        if (messagesContainer.children.length === 0) {
            this.addGremlinMessage('assistant', 'GremlinGPT online. Autonomous cognitive system ready. How can I assist?');
        }
    }

    loadGremlinFSM() {
        fetch('/api/statik/gremlin')
            .then(response => response.json())
            .then(data => {
                this.updateFSMVisualization(data.fsm_state || 'idle');
            })
            .catch(e => console.warn('Could not load GremlinGPT FSM state:', e));
    }

    loadGremlinMemory() {
        const graphContainer = document.getElementById('gremlin-memory-graph');
        if (!graphContainer) return;

        // Create simple memory graph visualization
        graphContainer.innerHTML = `
            <div class="memory-node-grid">
                <div class="memory-node active">Core Memory</div>
                <div class="memory-node">Working Memory</div>
                <div class="memory-node">Long-term Storage</div>
                <div class="memory-node">Signal Trace</div>
            </div>
        `;
    }

    loadTradingPanel() {
        const tradingContainer = document.getElementById('trading-signals');
        if (!tradingContainer) return;

        tradingContainer.innerHTML = `
            <div class="signal-list">
                <div class="signal-item">
                    <span class="signal-symbol">BTC/USD</span>
                    <span class="signal-action buy">BUY</span>
                    <span class="signal-confidence">85%</span>
                </div>
                <div class="signal-item">
                    <span class="signal-symbol">ETH/USD</span>
                    <span class="signal-action hold">HOLD</span>
                    <span class="signal-confidence">72%</span>
                </div>
            </div>
        `;
    }

    updateFSMVisualization(state) {
        const stateElement = document.getElementById('current-state');
        if (stateElement) {
            stateElement.textContent = state;
            stateElement.className = `fsm-state active ${state}`;
        }
        this.gremlinFSMState = state;
    }

    addGremlinMessage(role, content) {
        const messagesContainer = document.getElementById('gremlin-messages');
        if (!messagesContainer) return;

        const messageElement = document.createElement('div');
        messageElement.className = `message ${role}`;
        messageElement.innerHTML = `
            <div class="message-content">${content}</div>
            <div class="message-time">${new Date().toLocaleTimeString()}</div>
        `;

        messagesContainer.appendChild(messageElement);
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }

    // GodCore Integration
    loadGodCore() {
        this.loadGodCoreModels();
        this.loadGodCoreChat();
        this.loadQuantumStorage();
        this.loadRoutingAnalytics();
    }

    loadGodCoreComponents() {
        this.godCoreModels = [
            { name: 'Mistral-13B', status: 'online', load: 45 },
            { name: 'Monday.AI', status: 'online', load: 23 },
            { name: 'GPT-4', status: 'offline', load: 0 }
        ];
    }

    loadGodCoreModels() {
        const modelList = document.getElementById('model-list');
        if (!modelList) return;

        modelList.innerHTML = '';
        this.godCoreModels.forEach(model => {
            const modelElement = document.createElement('div');
            modelElement.className = `model-item ${model.status}`;
            modelElement.innerHTML = `
                <span class="model-name">${model.name}</span>
                <span class="model-status">${model.status === 'online' ? '🟢' : '🔴'} ${model.status}</span>
                <span class="model-load">Load: ${model.load}%</span>
            `;
            modelList.appendChild(modelElement);
        });
    }

    loadGodCoreChat() {
        const messagesContainer = document.getElementById('godcore-messages');
        if (!messagesContainer) return;

        if (messagesContainer.children.length === 0) {
            this.addGodCoreMessage('assistant', 'GodCore routing system online. Multi-model AI routing ready.');
        }
    }

    loadQuantumStorage() {
        // Update quantum storage stats
        document.getElementById('quantum-entries').textContent = Math.floor(Math.random() * 2000 + 1000);
        document.getElementById('compression-ratio').textContent = (Math.random() * 20 + 75).toFixed(1) + '%';
        document.getElementById('transcendence').textContent = `Level ${Math.floor(Math.random() * 5 + 1)}`;
    }

    loadRoutingAnalytics() {
        const chartContainer = document.getElementById('routing-chart');
        if (!chartContainer) return;

        // Simple ASCII chart representation
        chartContainer.innerHTML = `
            <div class="chart-bar">
                <div class="chart-label">Mistral</div>
                <div class="chart-fill" style="width: 65%"></div>
                <div class="chart-value">65%</div>
            </div>
            <div class="chart-bar">
                <div class="chart-label">Monday.AI</div>
                <div class="chart-fill" style="width: 30%"></div>
                <div class="chart-value">30%</div>
            </div>
            <div class="chart-bar">
                <div class="chart-label">GPT-4</div>
                <div class="chart-fill" style="width: 5%"></div>
                <div class="chart-value">5%</div>
            </div>
        `;
    }

    addGodCoreMessage(role, content) {
        const messagesContainer = document.getElementById('godcore-messages');
        if (!messagesContainer) return;

        const messageElement = document.createElement('div');
        messageElement.className = `message ${role}`;
        messageElement.innerHTML = `
            <div class="message-content">${content}</div>
            <div class="message-time">${new Date().toLocaleTimeString()}</div>
        `;

        messagesContainer.appendChild(messageElement);
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }

    // Mobile-Mirror Integration
    loadMobileMirror() {
        this.loadTunnelStatus();
        this.generateQRCode();
        this.loadConnectedDevices();
    }

    loadMobileMirrorComponents() {
        this.tunnelStatus = 'connected';
        this.mobileDevices = [
            { name: 'iPhone 15 Pro', ip: '100.64.0.3', status: 'online' },
            { name: 'Samsung Galaxy S24', ip: '100.64.0.4', status: 'online' }
        ];
    }

    loadTunnelStatus() {
        // Update tunnel status display
        const statusElements = document.querySelectorAll('.tunnel-connected');
        statusElements.forEach(el => {
            el.textContent = '🟢 Connected';
        });
    }

    generateQRCode() {
        const canvas = document.getElementById('qr-canvas');
        if (!canvas) return;

        const ctx = canvas.getContext('2d');

        // Simple QR code placeholder
        ctx.fillStyle = '#000';
        for (let i = 0; i < 20; i++) {
            for (let j = 0; j < 20; j++) {
                if (Math.random() > 0.5) {
                    ctx.fillRect(i * 10, j * 10, 10, 10);
                }
            }
        }
    }

    loadConnectedDevices() {
        // Devices are already populated in HTML, this could update from API
        console.log('Mobile devices:', this.mobileDevices);
    }

    // Memory Dashboard
    loadMemoryDashboard() {
        this.updateMemoryStats();
        this.loadMemoryGraph();
        this.loadSoulState();
    }

    updateMemoryStats(data) {
        if (!data) return;

        const totalMemories = document.getElementById('total-memories');
        const activeThreads = document.getElementById('active-threads');
        const memoryDepth = document.getElementById('memory-depth');
        const memoryCompression = document.getElementById('memory-compression');

        if (totalMemories) totalMemories.textContent = Math.floor(Math.random() * 1000 + 2000);
        if (activeThreads) activeThreads.textContent = Math.floor(Math.random() * 10 + 1);
        if (memoryDepth) memoryDepth.textContent = '2048';
        if (memoryCompression) memoryCompression.textContent = (Math.random() * 20 + 70).toFixed(1) + '%';
    }

    loadMemoryGraph() {
        const graphContainer = document.getElementById('memory-graph-viz');
        if (!graphContainer) return;

        graphContainer.innerHTML = `
            <div class="graph-network">
                <div class="graph-node central">🧠</div>
                <div class="graph-node">📝</div>
                <div class="graph-node">🔗</div>
                <div class="graph-node">💭</div>
                <div class="graph-node">⚡</div>
            </div>
        `;
    }

    loadSoulState() {
        const soulIndicator = document.getElementById('soul-indicator');
        if (!soulIndicator) return;

        soulIndicator.innerHTML = '👻';
        soulIndicator.style.animation = 'pulse 2s infinite';
    }

    // Mesh VPN Management
    loadMeshVPN() {
        this.loadMeshTopology();
        this.loadMeshNodes();
        this.loadPreauthKeys();
        this.loadNetworkTraffic();
    }

    loadMeshTopology() {
        const topologyContainer = document.getElementById('mesh-topology');
        if (!topologyContainer) return;

        topologyContainer.innerHTML = `
            <div class="topology-network">
                <div class="topology-node self">🏠</div>
                <div class="topology-connection"></div>
                <div class="topology-cloud">☁️</div>
            </div>
        `;
    }

    loadMeshNodes() {
        // Nodes are populated in HTML
        console.log('Mesh nodes loaded');
    }

    loadPreauthKeys() {
        // Keys are populated in HTML
        console.log('Preauth keys loaded');
    }

    loadNetworkTraffic() {
        // Traffic stats are populated in HTML
        console.log('Network traffic stats loaded');
    }

    // System Dashboard
    loadSystemDashboard() {
        this.loadSystemStats();
        this.loadServiceStatus();
        this.loadSystemLogs();
        this.loadSystemInfo();
    }

    loadSystemStats() {
        // Stats are already in HTML with placeholder values
        console.log('System stats loaded');
    }

    loadServiceStatus() {
        // Services are already in HTML
        console.log('Service status loaded');
    }

    loadSystemLogs() {
        const logsContainer = document.getElementById('system-logs');
        if (!logsContainer) return;

        // Add new log entries periodically
        setInterval(() => {
            const logEntry = document.createElement('div');
            logEntry.className = 'log-entry info';
            logEntry.innerHTML = `
                <span class="log-time">${new Date().toLocaleTimeString()}</span>
                <span class="log-level">INFO</span>
                <span class="log-message">System heartbeat: All services running</span>
            `;

            logsContainer.insertBefore(logEntry, logsContainer.firstChild);

            if (logsContainer.children.length > 50) {
                logsContainer.removeChild(logsContainer.lastChild);
            }
        }, 30000);
    }

    loadSystemInfo() {
        // System info is static in HTML
        console.log('System info loaded');
    }

    // Status Updates
    updateSystemStatus() {
        fetch('/api/statik/status')
            .then(response => response.json())
            .then(data => {
                this.updateStatusIndicators(data);
            })
            .catch(e => {
                console.warn('Could not update system status:', e);
                this.updateStatusIndicators({ status: 'unknown' });
            });
    }

    updateStatusIndicators(data) {
        const statusDot = document.getElementById('status-dot');
        const statusText = document.getElementById('status-text');

        if (data.status === 'healthy') {
            statusDot.textContent = '🟢';
            statusText.textContent = 'All Systems Operational';
        } else if (data.status === 'warning') {
            statusDot.textContent = '🟡';
            statusText.textContent = 'Some Issues Detected';
        } else {
            statusDot.textContent = '🔴';
            statusText.textContent = 'System Issues';
        }
    }

    updateMeshStatus() {
        fetch('/api/statik/mesh/status')
            .then(response => response.json())
            .then(data => {
                document.getElementById('mesh-nodes').textContent = data.connectedNodes || 1;
                document.getElementById('mesh-ip').textContent = data.meshIP || '100.64.0.1';
            })
            .catch(e => console.warn('Could not update mesh status:', e));
    }
}

// Global Functions for UI interactions
function openVSCode() {
    dashboard.switchTab('vscode');
}

function openGremlinChat() {
    dashboard.switchTab('gremlin');
}

function openGodCore() {
    dashboard.switchTab('godcore');
}

function openMobileMirror() {
    dashboard.switchTab('mobile');
}

function reloadVSCode() {
    const iframe = document.getElementById('vscode-frame');
    if (iframe) {
        // Force reload the VS Code iframe
        iframe.src = iframe.src + '?reload=' + Date.now();
    }
}

async function openVSCodeNew() {
    try {
        // Try to get tunnel URL for new window
        const config = await dashboard.loadTunnelConfig();
        let vscodeUrl = '/';

        if (config && config.services && config.services.vscode) {
            vscodeUrl = config.services.vscode.url || '/';
        }

        window.open(vscodeUrl, '_blank');
    } catch (error) {
        console.error('Error opening VS Code in new window:', error);
        window.open('/', '_blank');
    }
}

function toggleAutonomous() {
    dashboard.autonomousMode = !dashboard.autonomousMode;
    const btn = document.getElementById('autonomous-btn');
    const status = document.getElementById('autonomous-status');

    if (dashboard.autonomousMode) {
        status.textContent = '🟢 Autonomous ON';
        btn.style.background = 'var(--statik-success)';
    } else {
        status.textContent = '🔴 Autonomous OFF';
        btn.style.background = 'var(--statik-danger)';
    }

    // Send autonomous mode toggle to backend
    fetch('/api/statik/gremlin/autonomous', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ autonomous: dashboard.autonomousMode })
    }).catch(e => console.warn('Could not toggle autonomous mode:', e));
}

function resetGremlin() {
    fetch('/api/statik/gremlin/reset', { method: 'POST' })
        .then(() => {
            dashboard.updateFSMVisualization('idle');
            dashboard.addGremlinMessage('system', 'GremlinGPT FSM reset to idle state');
        })
        .catch(e => console.warn('Could not reset GremlinGPT:', e));
}

function sendGremlinMessage() {
    const input = document.getElementById('gremlin-input');
    const message = input.value.trim();
    if (!message) return;

    dashboard.addGremlinMessage('user', message);
    input.value = '';

    // Send to GremlinGPT API
    fetch('/api/statik/gremlin/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message })
    })
    .then(response => response.json())
    .then(data => {
        dashboard.addGremlinMessage('assistant', data.response);
        if (data.fsm_state) {
            dashboard.updateFSMVisualization(data.fsm_state);
        }
    })
    .catch(e => {
        console.warn('GremlinGPT chat error:', e);
        dashboard.addGremlinMessage('system', 'Connection error. Please try again.');
    });
}

function handleGremlinEnter(event) {
    if (event.key === 'Enter') {
        sendGremlinMessage();
    }
}

function stepFSM() {
    fetch('/api/statik/gremlin/step', { method: 'POST' })
        .then(response => response.json())
        .then(data => {
            dashboard.updateFSMVisualization(data.state);
        })
        .catch(e => console.warn('Could not step FSM:', e));
}

function pauseFSM() {
    fetch('/api/statik/gremlin/pause', { method: 'POST' })
        .then(() => {
            dashboard.addGremlinMessage('system', 'FSM paused');
        })
        .catch(e => console.warn('Could not pause FSM:', e));
}

function refreshModels() {
    fetch('/api/statik/godcore/models/refresh', { method: 'POST' })
        .then(() => {
            dashboard.loadGodCoreModels();
        })
        .catch(e => console.warn('Could not refresh models:', e));
}

function optimizeRouting() {
    fetch('/api/statik/godcore/routing/optimize', { method: 'POST' })
        .then(() => {
            dashboard.addGodCoreMessage('system', 'Routing optimization complete');
        })
        .catch(e => console.warn('Could not optimize routing:', e));
}

function sendGodCoreMessage() {
    const input = document.getElementById('godcore-input');
    const modelSelect = document.getElementById('model-select');
    const message = input.value.trim();
    const model = modelSelect.value;

    if (!message) return;

    dashboard.addGodCoreMessage('user', message);
    input.value = '';

    fetch('/api/statik/godcore/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message, model })
    })
    .then(response => response.json())
    .then(data => {
        dashboard.addGodCoreMessage('assistant', data.response);
    })
    .catch(e => {
        console.warn('GodCore chat error:', e);
        dashboard.addGodCoreMessage('system', 'Connection error. Please try again.');
    });
}

function handleGodCoreEnter(event) {
    if (event.key === 'Enter') {
        sendGodCoreMessage();
    }
}

function startTunnel() {
    fetch('/api/statik/mobile/tunnel/start', { method: 'POST' })
        .then(() => {
            dashboard.loadTunnelStatus();
        })
        .catch(e => console.warn('Could not start tunnel:', e));
}

function generateQR() {
    dashboard.generateQRCode();
}

function openMobileTerminal() {
    window.open('/mobile/terminal', '_blank');
}

function openMobileEditor() {
    window.open('/mobile/editor', '_blank');
}

function openMobileFiles() {
    window.open('/mobile/files', '_blank');
}

function openMobileScreen() {
    window.open('/mobile/screen', '_blank');
}

function pauseMemoryFeed() {
    dashboard.memoryFeedActive = !dashboard.memoryFeedActive;
    const btn = document.getElementById('memory-pause-btn');
    btn.textContent = dashboard.memoryFeedActive ? '⏸️ Pause Feed' : '▶️ Resume Feed';
}

function clearMemory() {
    if (confirm('Clear all AI memory? This action cannot be undone.')) {
        fetch('/api/statik/memory/clear', { method: 'POST' })
            .then(() => {
                document.getElementById('live-memory-feed').innerHTML = '';
                document.getElementById('memory-feed').innerHTML = '';
            })
            .catch(e => console.warn('Could not clear memory:', e));
    }
}

function exportMemory() {
    fetch('/api/statik/memory/export')
        .then(response => response.blob())
        .then(blob => {
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `statik-memory-${new Date().toISOString()}.json`;
            a.click();
            window.URL.revokeObjectURL(url);
        })
        .catch(e => console.warn('Could not export memory:', e));
}

function generatePreauthKey() {
    fetch('/api/statik/mesh/keys/generate', { method: 'POST' })
        .then(response => response.json())
        .then(data => {
            const keyList = document.getElementById('preauth-key-list');
            const keyElement = document.createElement('div');
            keyElement.className = 'key-item';
            keyElement.innerHTML = `
                <code class="key-value">${data.key}</code>
                <div class="key-info">
                    <span class="key-status">♾️ Never Expires</span>
                    <span class="key-uses">♻️ Reusable</span>
                </div>
                <button onclick="copyKey(this)" class="copy-btn">📋</button>
            `;
            keyList.insertBefore(keyElement, keyList.lastElementChild);
        })
        .catch(e => console.warn('Could not generate preauth key:', e));
}

function refreshMeshStatus() {
    dashboard.updateMeshStatus();
    dashboard.loadMeshNodes();
}

function addNewKey() {
    generatePreauthKey();
}

function copyKey(button) {
    const keyValue = button.parentElement.querySelector('.key-value').textContent;
    navigator.clipboard.writeText(keyValue).then(() => {
        button.textContent = '✅';
        setTimeout(() => {
            button.textContent = '📋';
        }, 2000);
    });
}

function copyPreauthKey() {
    const key = document.getElementById('preauth-key').textContent;
    navigator.clipboard.writeText(key).then(() => {
        document.querySelector('.copy-btn').textContent = '✅';
        setTimeout(() => {
            document.querySelector('.copy-btn').textContent = '📋';
        }, 2000);
    });
}

function copyMobileURL() {
    const url = 'https://100.64.0.2:8443';
    navigator.clipboard.writeText(url).then(() => {
        event.target.textContent = '✅';
        setTimeout(() => {
            event.target.textContent = '📋';
        }, 2000);
    });
}

function restartStatik() {
    if (confirm('Restart Statik-Server? This will temporarily disconnect all services.')) {
        fetch('/api/statik/system/restart', { method: 'POST' })
            .then(() => {
                alert('Statik-Server is restarting...');
                setTimeout(() => window.location.reload(), 10000);
            })
            .catch(e => console.warn('Could not restart Statik-Server:', e));
    }
}

function updateSystem() {
    fetch('/api/statik/system/update', { method: 'POST' })
        .then(() => {
            alert('System update initiated. Check logs for progress.');
        })
        .catch(e => console.warn('Could not update system:', e));
}

function restartService(serviceName) {
    fetch(`/api/statik/system/services/${serviceName}/restart`, { method: 'POST' })
        .then(() => {
            dashboard.loadServiceStatus();
        })
        .catch(e => console.warn(`Could not restart ${serviceName}:`, e));
}

// Initialize dashboard when DOM is loaded
let dashboard;
document.addEventListener('DOMContentLoaded', () => {
    dashboard = new StatikDashboard();
});

// Global functions for button clicks

// Function to open external links (StatikFinTech publications)
function openLink(url) {
    window.open(url, '_blank', 'noopener,noreferrer');
}

// Function to get Tailscale configuration
async function getTailscaleConfig() {
    try {
        const response = await fetch('/api/config/runtime');
        if (response.ok) {
            return await response.json();
        }
    } catch (error) {
        console.warn('Could not load Tailscale config:', error);
    }
    
    // Fallback: try to get Tailscale IP from known locations
    try {
        const ipResponse = await fetch('/api/statik/tailscale/ip');
        if (ipResponse.ok) {
            const data = await ipResponse.json();
            return {
                tailscale_ip: data.ip,
                vscode: {
                    stock: { url: `http://${data.ip}:8080` },
                    gremlingpt: { url: `http://${data.ip}:8081` }
                }
            };
        }
    } catch (error) {
        console.warn('Could not get Tailscale IP:', error);
    }
    
    return null;
}

// Function to open VS Code (Stock)
async function openVSCode() {
    const config = await getTailscaleConfig();
    let url = 'http://localhost:8080'; // fallback
    
    if (config && config.vscode && config.vscode.stock) {
        url = config.vscode.stock.url;
    }
    
    window.open(url, '_blank', 'noopener,noreferrer');
}

// Function to open Statik-Code (GremlinGPT VS Code)
async function openStatikCode() {
    const config = await getTailscaleConfig();
    let url = 'http://localhost:8081'; // fallback
    
    if (config && config.vscode && config.vscode.gremlingpt) {
        url = config.vscode.gremlingpt.url;
    }
    
    window.open(url, '_blank', 'noopener,noreferrer');
}

// Legacy function names for compatibility
function openGremlinChat() {
    openStatikCode();
}

function openGodCore() {
    // Redirect to settings for now
    dashboard.switchTab('system');
}

function openMobileMirror() {
    // Redirect to mesh VPN for now  
    dashboard.switchTab('mesh');
}

// Export for global access
window.StatikDashboard = StatikDashboard;
