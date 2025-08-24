import { Router } from "express"
import * as fs from "fs"
import * as path from "path"
import { promises as fsp } from "fs"

export const router = Router()

// API endpoint to serve runtime configuration for Tailscale integration
router.get("/config/runtime", async (req, res) => {
  try {
    const statikHome = path.join(process.env.HOME || "/tmp", ".statik-server")
    const configPath = path.join(statikHome, "config", "runtime.json")

    if (fs.existsSync(configPath)) {
      const configData = await fsp.readFile(configPath, "utf8")
      const config = JSON.parse(configData)
      res.json(config)
    } else {
      // Return default configuration
      res.json({
        mode: "development",
        tunneling: {
          enabled: false,
          provider: "none"
        },
        services: {
          frontend: {
            url: `http://localhost:${process.env.STATIK_FRONTEND_PORT || 3000}`,
            port: parseInt(process.env.STATIK_FRONTEND_PORT || "3000"),
            tunnel_active: false
          },
          vscode: {
            url: `http://localhost:${process.env.STATIK_VSCODE_PORT || 8080}`,
            port: parseInt(process.env.STATIK_VSCODE_PORT || "8080"),
            tunnel_active: false,
            iframe_src: "/"
          }
        },
        navigation: {
          default_page: "frontend",
          vscode_integration: "embedded_iframe"
        }
      })
    }
  } catch (error) {
    console.error("Error loading runtime config:", error)
    res.status(500).json({ error: "Failed to load configuration" })
  }
})

// API endpoint to get tunnel status
router.get("/tunnel/status", async (req, res) => {
  try {
    const statikHome = path.join(process.env.HOME || "/tmp", ".statik-server")
    const tunnelConfigPath = path.join(statikHome, "tunnel-config.json")

    if (fs.existsSync(tunnelConfigPath)) {
      const tunnelData = await fsp.readFile(tunnelConfigPath, "utf8")
      const tunnelConfig = JSON.parse(tunnelData)
      res.json(tunnelConfig)
    } else {
      res.json({
        tailscale_ip: null,
        frontend: { tunnel_active: false },
        vscode: { tunnel_active: false }
      })
    }
  } catch (error) {
    console.error("Error loading tunnel status:", error)
    res.status(500).json({ error: "Failed to load tunnel status" })
  }
})

export default router
