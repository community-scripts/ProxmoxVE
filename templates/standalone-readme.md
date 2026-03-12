# Heretek Proxmox Scripts

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/Heretek-AI/Heretek-Proxmox-Scripts)](https://github.com/Heretek-AI/Heretek-Proxmox-Scripts/commits/main)
[![GitHub stars](https://img.shields.io/github/stars/Heretek-AI/Heretek-Proxmox-Scripts?style=social)](https://github.com/Heretek-AI/Heretek-Proxmox-Scripts/stargazers)

Custom LXC container scripts for Proxmox VE - AI assistants, automation tools, and more.

## 📦 Available Scripts

| Script | Description | Type |
|--------|-------------|------|
| [agregarr](#agregarr) | Agregarr media aggregator | Container |
| [drop](#drop) | Drop file sharing | Container |
| [hermes](#hermes) | Hermes messaging | Container |
| [lemonade](#lemonade) | Lemonade media server | Container |
| [llamacpp](#llamacpp) | LlamaCPP AI inference | Container |
| [maintainerr](#maintainerr) | Maintainerr media management | Container |
| [mcphub](#mcphub) | MCPHub AI assistant | Container |
| [openclaw](#openclaw) | OpenClaw AI assistant | Container |
| [pegaprox](#pegaprox) | PegaProx proxy server | Container |
| [swarmui](#swarmui) | SwarmUI AI interface | Container |
| [wakapi](#wakapi) | Wakapi time tracking | Container |

## 🚀 Quick Start

### Install a Script

Each script can be run directly using:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Heretek-AI/Heretek-Proxmox-Scripts/main/ct/SCRIPT_NAME.sh)"
```

Replace `SCRIPT_NAME` with the desired script name (e.g., `openclaw`, `mcphub`).

### Example

```bash
# Install OpenClaw
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Heretek-AI/Heretek-Proxmox-Scripts/main/ct/openclaw.sh)"

# Install MCPHub
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Heretek-AI/Heretek-Proxmox-Scripts/main/ct/mcphub.sh)"
```

## ⚙️ Configuration

### URL Configuration

By default, scripts use base functions from `Heretek-AI/ProxmoxVE`:

```bash
COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/main}"
```

To use upstream base functions instead:

```bash
export COMMUNITY_SCRIPTS_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Heretek-AI/Heretek-Proxmox-Scripts/main/ct/openclaw.sh)"
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `COMMUNITY_SCRIPTS_URL` | `https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/main` | Base URL for script functions |

## 📖 Script Details

### agregarr

Agregarr is a media aggregator for managing your media collections.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Heretek-AI/Heretek-Proxmox-Scripts/main/ct/agregarr.sh)"
```

**Requirements:** Debian/Ubuntu LXC container

---

### drop

Drop is a self-hosted file sharing solution.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Heretek-AI/Heretek-Proxmox-Scripts/main/ct/drop.sh)"
```

**Requirements:** Debian/Ubuntu LXC container

---

### hermes

Hermes is a messaging platform for secure communications.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Heretek-AI/Heretek-Proxmox-Scripts/main/ct/hermes.sh)"
```

**Requirements:** Debian/Ubuntu LXC container

---

### lemonade

Lemonade is a media server for streaming your content.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Heretek-AI/Heretek-Proxmox-Scripts/main/ct/lemonade.sh)"
```

**Requirements:** Debian/Ubuntu LXC container

---

### llamacpp

LlamaCPP is a high-performance AI inference engine for running LLM models locally.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Heretek-AI/Heretek-Proxmox-Scripts/main/ct/llamacpp.sh)"
```

**Requirements:** Debian/Ubuntu LXC container, recommended GPU support

---

### maintainerr

Maintainerr is a media management tool for organizing and maintaining your media library.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Heretek-AI/Heretek-Proxmox-Scripts/main/ct/maintainerr.sh)"
```

**Requirements:** Debian/Ubuntu LXC container

---

### mcphub

MCPHub is an AI assistant platform based on the Model Context Protocol.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Heretek-AI/Heretek-Proxmox-Scripts/main/ct/mcphub.sh)"
```

**Requirements:** Debian/Ubuntu LXC container, Node.js

---

### openclaw

OpenClaw is an AI assistant for automation and productivity.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Heretek-AI/Heretek-Proxmox-Scripts/main/ct/openclaw.sh)"
```

**Requirements:** Debian/Ubuntu LXC container, Node.js 22+

---

### pegaprox

PegaProx is a proxy server for secure network access.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Heretek-AI/Heretek-Proxmox-Scripts/main/ct/pegaprox.sh)"
```

**Requirements:** Debian/Ubuntu LXC container

---

### swarmui

SwarmUI is a web interface for AI model management and inference.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Heretek-AI/Heretek-Proxmox-Scripts/main/ct/swarmui.sh)"
```

**Requirements:** Debian/Ubuntu LXC container, recommended GPU support

---

### wakapi

Wakapi is a self-hosted time tracking tool for developers.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Heretek-AI/Heretek-Proxmox-Scripts/main/ct/wakapi.sh)"
```

**Requirements:** Debian/Ubuntu LXC container

---

## 🔗 Source Repository

These scripts are maintained in [Heretek-AI/ProxmoxVE](https://github.com/Heretek-AI/ProxmoxVE) and automatically synced here.

### Related Projects

- **Upstream:** [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE) - The original Proxmox VE scripts collection
- **Fork:** [Heretek-AI/ProxmoxVE](https://github.com/Heretek-AI/ProxmoxVE) - Our fork with additional customizations

## 🤝 Contributing

Contributions are welcome! Please submit pull requests to the [main repository](https://github.com/Heretek-AI/ProxmoxVE).

## 📝 License

MIT License - See [LICENSE](LICENSE) for details.

## ⚠️ Disclaimer

These scripts are provided as-is. Always review scripts before running them on your system. Use at your own risk.

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/Heretek-AI">Heretek-AI</a>
</p>
