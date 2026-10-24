#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: havardthom | Co-Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ollama.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y zstd
msg_ok "Installed Dependencies"

setup_hwaccel

# Ollama's bundled Vulkan backend is what drives Intel and non-ROCm AMD GPUs;
# it only needs the Mesa Vulkan drivers, which setup_hwaccel does not install for AMD.
if [[ -d /dev/dri ]]; then
  msg_info "Installing Vulkan Drivers"
  $STD apt install -y mesa-vulkan-drivers
  msg_ok "Installed Vulkan Drivers"
fi

fetch_and_deploy_gh_release "ollama-com" "ollama/ollama" "prebuild" "latest" "/usr/local/lib/ollama" "ollama-linux-$(arch_resolve).tar.zst"
# The ROCm archive holds a single lib/ directory, which the helper strips, so it is deployed into lib/.
if [[ -e /dev/kfd && "$(arch_resolve)" == "amd64" ]]; then
  fetch_and_deploy_gh_release "ollama-rocm-com" "ollama/ollama" "prebuild" "latest" "/usr/local/lib/ollama/lib" "ollama-linux-amd64-rocm.tar.zst"
fi
ln -sf /usr/local/lib/ollama/bin/ollama /usr/local/bin/ollama

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/ollama.service
[Unit]
Description=Ollama Service
After=network-online.target
Wants=network-online.target

[Service]
Type=exec
ExecStart=/usr/local/bin/ollama serve
Environment=HOME=/root
Environment=OLLAMA_HOST=0.0.0.0
Environment=OLLAMA_IGPU_ENABLE=1
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now ollama
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
