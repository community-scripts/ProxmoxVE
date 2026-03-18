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
PYTHON_VERSION="3.13" setup_uv

msg_info "Creating Virtual Environment"
mkdir -p /opt/unsolth-studio
cd /opt/unsolth-studio || exit
$STD uv venv --python 3.13
source .venv/bin/activate
msg_ok "Created Virtual Environment"

msg_info "Detecting GPU Type for PyTorch Installation"
# Detect GPU type based on what setup_hwaccel installed
# setup_hwaccel runs before this and installs NVIDIA drivers or ROCm

GPU_TYPE="cpu"

# Check for NVIDIA GPU (nvidia-smi installed by setup_hwaccel)
if command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null; then
  GPU_TYPE="nvidia"
  msg_info "NVIDIA GPU detected - installing PyTorch with CUDA support"
# Check for AMD GPU (ROCm installed by setup_hwaccel at /opt/rocm)
elif [ -d "/opt/rocm" ] || [ -d "/opt/rocm-7.2" ] || [ -d "/opt/rocm-6.2" ]; then
  GPU_TYPE="amd"
  msg_info "AMD GPU detected (ROCm installed) - installing PyTorch with ROCm support"
# Check for AMD render devices (GPU passthrough configured)
elif ls /dev/dri/renderD* &>/dev/null 2>&1; then
  # Check if any render device is AMD
  for render_dev in /dev/dri/renderD*; do
    if [ -e "$render_dev" ]; then
      GPU_TYPE="amd"
      msg_info "AMD GPU detected (render device) - installing PyTorch with ROCm support"
      break
    fi
  done
fi

if [ "$GPU_TYPE" = "nvidia" ]; then
  # NVIDIA GPU - install PyTorch with CUDA 12.4 support
  $STD uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
  msg_ok "Installed PyTorch with CUDA Support"
elif [ "$GPU_TYPE" = "amd" ]; then
  # AMD GPU - install PyTorch with ROCm 7.2 support
  $STD uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/test/rocm7.2
  msg_ok "Installed PyTorch with ROCm Support"
else
  # No GPU detected - install CPU version
  msg_info "No GPU detected - installing PyTorch CPU version"
  $STD uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
  msg_ok "Installed PyTorch (CPU version)"
fi

msg_info "Installing Unsloth"
# Install unsloth and its dependencies
# packaging module is required but not declared as dependency
$STD uv pip install unsloth packaging
msg_ok "Installed Unsloth"

msg_info "Running Unsloth Studio Setup"
# Run the unsloth studio setup command to compile llama.cpp
# This requires GPU access - set up environment for ROCm if installed

# Set up ROCm environment if available
# Use ${VAR:-} to handle unset variables (set -u causes errors otherwise)
if [ -d "/opt/rocm" ]; then
  export PATH="/opt/rocm/bin:$PATH"
  export LD_LIBRARY_PATH="/opt/rocm/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  export ROCM_PATH="/opt/rocm"
elif [ -d "/opt/rocm-7.2" ]; then
  export PATH="/opt/rocm-7.2/bin:$PATH"
  export LD_LIBRARY_PATH="/opt/rocm-7.2/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  export ROCM_PATH="/opt/rocm-7.2"
elif [ -d "/opt/rocm-6.2" ]; then
  export PATH="/opt/rocm-6.2/bin:$PATH"
  export LD_LIBRARY_PATH="/opt/rocm-6.2/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  export ROCM_PATH="/opt/rocm-6.2"
fi

# Check if GPU is available (works for both CUDA and ROCm)
if /opt/unsolth-studio/.venv/bin/python -c "import torch; exit(0 if torch.cuda.is_available() else 1)" 2>/dev/null; then
  # Use the unsloth CLI entry point instead of python -m unsloth
  # The package installs a 'unsloth' command that provides the studio subcommand
  $STD /opt/unsolth-studio/.venv/bin/unsloth studio setup
  msg_ok "Completed Unsloth Studio Setup"
else
  msg_info "GPU not detected via torch.cuda - skipping Unsloth Studio setup"
  msg_info "This may be normal if ROCm libraries need system restart to take effect"
  echo ""
  echo -e "${GN}Note: If you have GPU passthrough configured, try:${CL}"
  echo -e "${GN}  1. Restart the container: pct stop <CTID> && pct start <CTID>${CL}"
  echo -e "${GN}  2. Then run: source /opt/unsolth-studio/.venv/bin/activate && unsloth studio setup${CL}"
  echo ""
fi

msg_info "Creating Directories"
mkdir -p /opt/unsolth-studio/models
mkdir -p /opt/unsolth-studio/datasets
mkdir -p /var/log/unsolth-studio
chmod 755 /var/log/unsolth-studio
msg_ok "Created Directories"

msg_info "Creating Service"
# Create environment file for ROCm/CUDA paths
cat <<EOF >/opt/unsolth-studio/environment.sh
#!/bin/bash
# Set up GPU environment for Unsloth Studio

# ROCm environment (AMD GPUs)
if [ -d "/opt/rocm" ]; then
  export PATH="/opt/rocm/bin:\$PATH"
  export LD_LIBRARY_PATH="/opt/rocm/lib:\$LD_LIBRARY_PATH"
  export ROCM_PATH="/opt/rocm"
elif [ -d "/opt/rocm-7.2" ]; then
  export PATH="/opt/rocm-7.2/bin:\$PATH"
  export LD_LIBRARY_PATH="/opt/rocm-7.2/lib:\$LD_LIBRARY_PATH"
  export ROCM_PATH="/opt/rocm-7.2"
elif [ -d "/opt/rocm-6.2" ]; then
  export PATH="/opt/rocm-6.2/bin:\$PATH"
  export LD_LIBRARY_PATH="/opt/rocm-6.2/lib:\$LD_LIBRARY_PATH"
  export ROCM_PATH="/opt/rocm-6.2"
fi

# NVIDIA CUDA environment
if [ -d "/usr/local/cuda" ]; then
  export PATH="/usr/local/cuda/bin:\$PATH"
  export LD_LIBRARY_PATH="/usr/local/cuda/lib64:\$LD_LIBRARY_PATH"
fi
EOF
chmod +x /opt/unsolth-studio/environment.sh

cat <<EOF >/etc/systemd/system/unsolth-studio.service
[Unit]
Description=Unsloth Studio - Local LLM Fine-tuning Web UI
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/unsolth-studio
Environment="PATH=/opt/unsolth-studio/.venv/bin:/usr/local/bin:/usr/bin:/bin"
EnvironmentFile=/opt/unsolth-studio/environment.sh
ExecStart=/opt/unsolth-studio/.venv/bin/unsloth studio -H 0.0.0.0 -p 8888
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
# Don't auto-start the service since GPU passthrough may not be configured yet
# User needs to configure GPU passthrough first, then start the service manually
systemctl enable -q unsolth-studio
msg_ok "Created Service"
echo ""
echo -e "${GN}Note: The unsolth-studio service is enabled but not started.${CL}"
echo -e "${GN}Configure GPU passthrough first, then start with:${CL}"
echo -e "${GN}  systemctl start unsolth-studio${CL}"
echo ""

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
