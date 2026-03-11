# llama.cpp Server Script Plan for ProxmoxVE

## Overview

This plan outlines the creation of a ProxmoxVE LXC container script for deploying **llama.cpp server** with GPU passthrough and Vulkan backend support. The script will install the latest Vulkan build and configure a default model for immediate use.

## Reference Links

- **GitHub Discussion**: https://github.com/community-scripts/ProxmoxVE/discussions/2403
- **llama.cpp Repository**: https://github.com/ggml-org/llama.cpp
- **llama.cpp Server Documentation**: https://github.com/ggml-org/llama.cpp/tree/master/tools/server
- **Vulkan Build Downloads**: https://github.com/ggml-org/llama.cpp/releases

## Implementation Status

✅ **COMPLETED** - All files have been created.

## Files Created

### 1. Container Script: `ct/llamacpp.sh`

**Purpose**: Main script for creating the LXC container

**Key Features**:
- Debian 13 base (recommended for latest Vulkan support)
- GPU passthrough enabled via `var_gpu="yes"`
- 4 CPU cores, 8GB RAM minimum (model requires ~10GB for Q8_0)
- 20GB disk (model + binaries + cache)
- Auto-detects GPU type (AMD/Intel/NVIDIA) during updates
- Downloads appropriate build (Vulkan or CUDA)

### 2. Installation Script: `install/llamacpp-install.sh`

**Purpose**: Install llama.cpp with Vulkan support inside the container

**Key Features**:
- Auto-detects GPU vendor (AMD/Intel/NVIDIA)
- Downloads latest Vulkan build from GitHub releases
- Falls back to Vulkan if CUDA download fails
- Creates systemd service with default model
- Configures GPU permissions automatically
- Creates GPU passthrough documentation file

### 3. JSON Metadata: `frontend/public/json/llamacpp.json`

**Purpose**: Frontend metadata for the script catalog

**Key Features**:
- Category: AI/ML (0)
- Port: 8080
- Updateable: true
- Comprehensive notes for GPU passthrough

### 4. Header File: `ct/headers/llamacpp`

**Purpose**: ASCII art header for the script

## Default Configuration

| Setting | Value |
|---------|-------|
| Model | `unsloth/Qwen3.5-9B-GGUF:Q8_0` |
| Port | 8080 |
| Context Size | 8192 tokens |
| GPU Layers | -1 (all layers on GPU) |
| Host | 0.0.0.0 (all interfaces) |

## GPU Passthrough Configuration

### AMD GPU Configuration

Add to `/etc/pve/lxc/<CTID>.conf`:
```ini
dev0: /dev/kfd,gid=104
dev1: /dev/dri/renderD128,gid=104
lxc.cgroup2.devices.allow: c 226:0 rwm
lxc.cgroup2.devices.allow: c 226:128 rwm
```

### Intel GPU Configuration

Add to `/etc/pve/lxc/<CTID>.conf`:
```ini
dev0: /dev/dri/renderD128,gid=104
lxc.cgroup2.devices.allow: c 226:128 rwm
```

### NVIDIA GPU Configuration

For NVIDIA, use the nvidia-container-toolkit approach:
```ini
lxc.cgroup2.devices.allow: c 195:* rwm
lxc.cgroup2.devices.allow: c 509:* rwm
```

## API Endpoints

The server provides OpenAI-compatible endpoints:

| Endpoint | Description |
|----------|-------------|
| `POST /v1/chat/completions` | Chat completion |
| `POST /v1/completions` | Text completion |
| `POST /v1/embeddings` | Text embeddings |
| `GET /v1/models` | List available models |
| `GET /health` | Health check |
| `GET /` | Built-in Web UI |

## Resource Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 2 cores | 4+ cores |
| RAM | 8GB | 16GB+ |
| Disk | 20GB | 50GB+ |
| GPU | Vulkan 1.1+ | Vulkan 1.3+ |

## Testing Checklist

- [ ] Container creation succeeds
- [ ] GPU passthrough is detected (`vulkaninfo` works)
- [ ] llama.cpp server starts successfully
- [ ] Model downloads automatically from HuggingFace
- [ ] API responds on port 8080
- [ ] Chat completion endpoint works
- [ ] Update script functions correctly
- [ ] Service restarts after reboot

## Usage Examples

### Chat Completion (curl)

```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Hello!"}],
    "temperature": 0.7,
    "max_tokens": 100
  }'
```

### Change Model

```bash
# Edit the service file
nano /etc/systemd/system/llamacpp.service

# Change the -hf parameter
# Example: -hf TheBloke/Llama-2-7B-GGUF:Q4_K_M

# Reload and restart
systemctl daemon-reload
systemctl restart llamacpp
```

### Check Logs

```bash
journalctl -u llamacpp -f
```

## Files Summary

| File | Purpose |
|------|---------|
| `ct/llamacpp.sh` | Container creation script |
| `install/llamacpp-install.sh` | Installation script |
| `frontend/public/json/llamacpp.json` | Frontend metadata |
| `ct/headers/llamacpp` | ASCII art header |
| `plans/llamacpp-server-plan.md` | This documentation |

## Next Steps

1. Test the script on a Proxmox VE 8.x host with GPU passthrough
2. Verify GPU detection works for AMD, Intel, and NVIDIA
3. Test model download and inference
4. Verify update mechanism works correctly
