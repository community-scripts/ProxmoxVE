#!/usr/bin/env bash

# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ggml-org/llama.cpp

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
  ca-certificates \
  vulkan-tools \
  libvulkan1 \
  mesa-vulkan-drivers \
  firmware-misc-nonfree \
  pciutils
msg_ok "Installed Dependencies"

# Create directories
mkdir -p /opt/llamacpp/bin
mkdir -p /opt/llamacpp/models

# Download llama.cpp using fetch_and_deploy_gh_release (Vulkan build)
fetch_and_deploy_gh_release "llamacpp" "ggml-org/llama.cpp" "prebuild" "latest" "/opt/llamacpp/bin" "llama-*-bin-ubuntu-vulkan-x64.tar.gz"

# Create symlinks for easy access
ln -sf /opt/llamacpp/bin/llama-server /usr/local/bin/llama-server
ln -sf /opt/llamacpp/bin/llama-cli /usr/local/bin/llama-cli

msg_info "Creating Directories"
mkdir -p /var/log/llamacpp
chmod 755 /var/log/llamacpp
msg_ok "Created Directories"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/llamacpp.service
[Unit]
Description=llama.cpp Server - OpenAI-Compatible LLM Inference
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/llamacpp
ExecStart=/opt/llamacpp/bin/llama-server -hf unsloth/Qwen3.5-9B-GGUF:Q8_0 --host 0.0.0.0 --port 8080 --ctx-size 8192 --n-gpu-layers -1
Restart=always
RestartSec=10
Environment=LLAMA_LOG_LEVEL=info
StandardOutput=journal
StandardError=journal
SyslogIdentifier=llamacpp

# Resource limits
LimitNOFILE=65535
TimeoutStartSec=300
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now llamacpp
msg_ok "Created Service"

msg_info "Configuring GPU Permissions"
# Add render and video groups for GPU access
usermod -aG render,video root 2>/dev/null || true

# Configure /dev/kfd and /dev/dri permissions for AMD
if [[ -e /dev/kfd ]]; then
  chgrp render /dev/kfd 2>/dev/null || true
  chmod 660 /dev/kfd 2>/dev/null || true
fi

if [[ -d /dev/dri ]]; then
  chmod 755 /dev/dri 2>/dev/null || true
  for render_dev in /dev/dri/renderD*; do
    if [[ -e "$render_dev" ]]; then
      chgrp render "$render_dev" 2>/dev/null || true
      chmod 660 "$render_dev" 2>/dev/null || true
    fi
  done
fi
msg_ok "Configured GPU Permissions"

# Create GPU passthrough info file
cat <<EOF >/opt/llamacpp/GPU_PASSTHROUGH.md
# GPU Passthrough Configuration for llama.cpp

This container has been configured for GPU acceleration using Vulkan.

## Required Proxmox Configuration

Add the following lines to your container config file:
/etc/pve/lxc/<CTID>.conf

### For AMD GPUs:
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

### For NVIDIA GPUs:
\`\`\`
# Requires nvidia-container-toolkit on host
lxc.cgroup2.devices.allow: c 195:* rwm
lxc.cgroup2.devices.allow: c 509:* rwm
\`\`\`

## Verify GPU Access

Run these commands inside the container:
- vulkaninfo (check Vulkan support)
- /opt/llamacpp/bin/llama-cli --help (verify binary works)

## Change Model

Edit /etc/systemd/system/llamacpp.service and modify the -hf parameter:
-hf <huggingface-model>:<quantization>

Examples:
-hf unsloth/Qwen3.5-9B-GGUF:Q8_0
-hf TheBloke/Llama-2-7B-GGUF:Q4_K_M
-hf mistralai/Mistral-7B-Instruct-v0.2-GGUF:Q5_K_M

After changing:
systemctl daemon-reload
systemctl restart llamacpp
EOF

motd_ssh
customize
cleanup_lxc

echo -e "${TAB}${GN}llama.cpp Server has been installed successfully!${CL}"
echo -e "${TAB}${YW}Default Model: unsloth/Qwen3.5-9B-GGUF:Q8_0${CL}"
echo -e "${TAB}${YW}The model will be downloaded automatically on first start.${CL}"
echo ""
echo -e "${TAB}${YW}GPU Passthrough:${CL}"
echo -e "${TAB}${YW}See /opt/llamacpp/GPU_PASSTHROUGH.md for configuration details.${CL}"
echo ""
echo -e "${TAB}${YW}Access the Web UI at: http://${IP}:8080${CL}"
echo -e "${TAB}${YW}OpenAI-Compatible API: http://${IP}:8080/v1/chat/completions${CL}"
