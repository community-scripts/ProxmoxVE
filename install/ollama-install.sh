#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
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
$STD apt-get install -y \
  build-essential \
  pkg-config
msg_ok "Installed Dependencies"

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
RELEASE=$(curl -fsSL https://api.github.com/repos/ollama/ollama/releases/latest | grep "tag_name" | awk -F '"' '{print $4}')
OLLAMA_INSTALL_DIR="/usr/local/lib/ollama"
BINDIR="/usr/local/bin"
mkdir -p $OLLAMA_INSTALL_DIR
OLLAMA_URL="https://github.com/ollama/ollama/releases/download/${RELEASE}/ollama-linux-amd64.tgz"
TMP_TAR="/tmp/ollama.tgz"
echo -e "\n"
if curl -fL# -o "$TMP_TAR" "$OLLAMA_URL"; then
  if tar -xzf "$TMP_TAR" -C "$OLLAMA_INSTALL_DIR"; then
    ln -sf "$OLLAMA_INSTALL_DIR/bin/ollama" "$BINDIR/ollama"
    echo "${RELEASE}" >/opt/Ollama_version.txt
    msg_ok "Installed Ollama ${RELEASE}"
  else
    msg_error "Extraction failed – archive corrupt or incomplete"
    exit 1
  fi
else
  msg_error "Download failed – $OLLAMA_URL not reachable"
  exit 1
fi

msg_info "Creating ollama User and Group"
if ! id ollama >/dev/null 2>&1; then
  useradd -r -s /usr/sbin/nologin -U -m -d /usr/share/ollama ollama
fi
$STD usermod -aG render ollama || true
$STD usermod -aG video ollama || true
$STD usermod -aG ollama $(id -u -n)
msg_ok "Created ollama User and adjusted Groups"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/ollama.service
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
Type=exec
ExecStart=/usr/local/bin/ollama serve
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
systemctl enable -q --now ollama
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
