#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: havardthom
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y gpg
$STD apt-get install -y git
$STD apt-get install -y build-essential
$STD apt-get install -y pkg-config
$STD apt-get install -y cmake
msg_ok "Installed Dependencies"

msg_info "Installing Golang"
$STD wget https://golang.org/dl/go1.23.2.linux-amd64.tar.gz
$STD tar -xzf go1.23.2.linux-amd64.tar.gz -C /usr/local
$STD ln -s /usr/local/go/bin/go /usr/local/bin/go
rm -rf go1.23.2.linux-amd64.tar.gz
msg_ok "Installed Golang"

msg_info "Setting up Intel® Repositories"
mkdir -p /etc/apt/keyrings
curl -fsSL https://repositories.intel.com/gpu/intel-graphics.key | gpg --dearmor -o /etc/apt/keyrings/intel-graphics.gpg
echo "deb [arch=amd64,i386 signed-by=/etc/apt/keyrings/intel-graphics.gpg] https://repositories.intel.com/gpu/ubuntu jammy client" >/etc/apt/sources.list.d/intel-gpu-jammy.list
curl -fsSL https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor -o /etc/apt/keyrings/oneapi-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" >/etc/apt/sources.list.d/oneAPI.list
$STD apt-get update
msg_ok "Set up Intel® Repositories"

msg_info "Setting Up Hardware Acceleration"
$STD apt-get -y install {va-driver-all,ocl-icd-libopencl1,intel-opencl-icd,vainfo,intel-gpu-tools,intel-level-zero-gpu,level-zero,level-zero-dev}
if [[ "$CTTYPE" == "0" ]]; then
  chgrp video /dev/dri
  chmod 755 /dev/dri
  chmod 660 /dev/dri/*
  $STD adduser $(id -u -n) video
  $STD adduser $(id -u -n) render
fi
msg_ok "Set Up Hardware Acceleration"

msg_info "Installing Intel® oneAPI Base Toolkit (Patience)"
$STD apt-get install -y --no-install-recommends intel-basekit-2024.1
msg_ok "Installed Intel® oneAPI Base Toolkit"

msg_info "Installing Ollama (Patience)"
$STD git clone https://github.com/ollama/ollama.git /opt/ollama
cd /opt/ollama
$STD go generate ./...
$STD go build .
msg_ok "Installed Ollama"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/ollama.service
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
Type=exec
ExecStart=/opt/ollama/ollama serve
Environment=HOME=$HOME
Environment=OLLAMA_INTEL_GPU=true
Environment=OLLAMA_HOST=0.0.0.0
Environment=OLLAMA_NUM_GPU=999
Environment=SYCL_CACHE_PERSISTENT=1
Environment=ZES_ENABLE_SYSMAN=1
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now ollama.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
