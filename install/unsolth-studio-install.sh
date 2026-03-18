#!/usr/bin/env bash

# Author: Heretek-AI
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/unslothai/unsloth

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  wget \
  git \
  cmake \
  build-essential \
  python3 \
  python3-pip \
  python3-venv \
  pciutils
msg_ok "Installed Dependencies"

# Setup GPU hardware acceleration FIRST (detects GPU, installs drivers, configures permissions)
# This must run before installing unsloth/torch so PyTorch can detect the GPU
setup_hwaccel

# Setup Python virtual environment with uv (fast Python package manager)
PYTHON_VERSION="3.12" setup_uv

msg_info "Creating Virtual Environment"
mkdir -p /opt/unsolth-studio
cd /opt/unsolth-studio || exit
$STD uv venv --python 3.12
source .venv/bin/activate
msg_ok "Created Virtual Environment"

msg_info "Installing Unsloth"
# Install unsloth with torch backend auto-detection (GPU drivers must be installed first)
$STD uv pip install unsloth --torch-backend=auto
msg_ok "Installed Unsloth"

msg_info "Running Unsloth Studio Setup"
# Run the unsloth studio setup command to compile llama.cpp
# Use Python module invocation since uv pip install doesn't create entry points
$STD /opt/unsolth-studio/.venv/bin/python -m unsloth studio setup
msg_ok "Completed Unsloth Studio Setup"

msg_info "Creating Directories"
mkdir -p /opt/unsolth-studio/models
mkdir -p /opt/unsolth-studio/datasets
mkdir -p /var/log/unsolth-studio
chmod 755 /var/log/unsolth-studio
msg_ok "Created Directories"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/unsolth-studio.service
[Unit]
Description=Unsloth Studio - Local LLM Fine-tuning Web UI
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/unsolth-studio
Environment="PATH=/opt/unsolth-studio/.venv/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=/opt/unsolth-studio/.venv/bin/python -m unsloth studio -H 0.0.0.0 -p 8888
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=unsolth-studio

# Resource limits
LimitNOFILE=65535
TimeoutStartSec=600
TimeoutStopSec=60

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now unsolth-studio
msg_ok "Created Service"

# Create GPU passthrough info file
cat <<EOF >/opt/unsolth-studio/GPU_PASSTHROUGH.md
# GPU Passthrough Configuration for Unsloth Studio

This container has been configured for GPU acceleration for LLM fine-tuning.

## Required Proxmox Configuration

Add the following lines to your container config file:
/etc/pve/lxc/<CTID>.conf

### For NVIDIA GPUs:
\`\`\`
# Requires nvidia-container-toolkit on host
lxc.cgroup2.devices.allow: c 195:* rwm
lxc.cgroup2.devices.allow: c 509:* rwm
dev0: /dev/nvidia0,gid=104
dev1: /dev/nvidiactl,gid=104
dev2: /dev/nvidia-uvm,gid=104
dev3: /dev/nvidia-uvm-tools,gid=104
\`\`\`

### For AMD GPUs (ROCm):
\`\`\`
dev0: /dev/kfd,gid=104
dev1: /dev/dri/renderD128,gid=104
lxc.cgroup2.devices.allow: c 226:0 rwm
lxc.cgroup2.devices.allow: c 226:128 rwm
\`\`\`

### For Intel GPUs:
\`\`\`
dev0: /dev/dri/renderD128,gid=104
lxc.cgroup2.devices.allow: c 226:128 rwm
\`\`\`

## Verify GPU Access

Run these commands inside the container:
- nvidia-smi (NVIDIA GPUs)
- rocminfo (AMD GPUs)
- python -c "import torch; print(torch.cuda.is_available())"

## Usage

Access the web UI at: http://<IP>:8888

On first launch:
1. Create a password to secure your account
2. Follow the onboarding wizard to select a model and dataset
3. Configure training parameters
4. Start fine-tuning!

## Supported Models

Unsloth Studio supports fine-tuning many LLM models including:
- Llama 3.x
- Qwen 2.x / 3.x
- Mistral
- Gemma
- Phi-3
- And many more...

## Documentation

- Official Docs: https://unsloth.ai/docs/new/studio/start
- GitHub: https://github.com/unslothai/unsloth
EOF

motd_ssh
customize
cleanup_lxc
