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
$STD apt install -y \
  build-essential \
  pkg-config \
  zstd
msg_ok "Installed Dependencies"

# Setup menu of GPUs to support
local menu_items=(
  1 "NVIDIA" "off"
  2 "AMD" "off"
  3 "Intel" "off"
)

# Pick which GPUs to support
# I should allow this to be overrideable
local GPU_CHOICE
GPU_CHOICE=$(whiptail \
  --backtitle "Ollama" \
  --title "GPU Support" \
  --ok-button "Select" --cancel-button "Exit Script" \
  --notags \
  --checklist "\nChoose a options:\n Use TAB or Arrow keys to navigate, ENTER to select.\n" \
  20 60 9 \
  "${menu_items[@]}" \
  --default-item "1" \
  3>&1 1>&2 2>&3) || exit_script

for selected_gpu_type in $(echo $GPU_CHOICE | tr -d \"); do
  case "$selected_gpu_type" in
  1)
    msg_info "NVIDIA Not yet supported"
    ;;
  2)
    msg_info "Setting up AMD® Repositories and ROCM"
    # Following the documented procedure exactly
    # https://rocm.docs.amd.com/projects/install-on-linux/en/docs-7.2.2/install/quick-start.html
    curl -fsSL -o /tmp/amdgpu-install_7.2.2.70202-1_all.deb https://repo.radeon.com/amdgpu-install/7.2.2/ubuntu/noble/amdgpu-install_7.2.2.70202-1_all.deb
    $STD apt -y install /tmp/amdgpu-install_7.2.2.70202-1_all.deb
    sed -i "s|graphics/7.2.2|graphics/7.2.1|" /etc/apt/sources.list.d/rocm.list
    # Not required for proxmox
    # apt install amdgpu-dkms
    $STD apt -y install python3-setuptools python3-wheel 2>/dev/null || {
        msg_warn "Failed to install deps for AMD ROCM, continuing anyway"
      }
    # Update to pull in rocm
    $STD apt update 2>/dev/null || {
        msg_warn "Failed to update DB, continuing anyway"
      }
    $STD apt -y install rocm 2>/dev/null || {
        msg_warn "Failed to install ROCM, continuing anyway"
      }
    msg_ok "AMD® ROCM installed"
    ;;
  3)
    msg_info "Setting up Intel® Repositories"
    mkdir -p /usr/share/keyrings
    curl -fsSL https://repositories.intel.com/gpu/intel-graphics.key | gpg --dearmor -o /usr/share/keyrings/intel-graphics.gpg 2>/dev/null || true
    cat <<EOF >/etc/apt/sources.list.d/intel-gpu.sources
    Types: deb
    URIs: https://repositories.intel.com/gpu/ubuntu
    Suites: jammy
    Components: client
    Architectures: amd64 i386
    Signed-By: /usr/share/keyrings/intel-graphics.gpg
EOF
    curl -fsSL https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor -o /usr/share/keyrings/oneapi-archive-keyring.gpg 2>/dev/null || true
    cat <<EOF >/etc/apt/sources.list.d/oneAPI.sources
    Types: deb
    URIs: https://apt.repos.intel.com/oneapi
    Suites: all
    Components: main
    Signed-By: /usr/share/keyrings/oneapi-archive-keyring.gpg
EOF
    $STD apt update
    msg_ok "Set up Intel® Repositories"

    msg_info "Installing Intel® Level Zero"
    # Debian 13+ has newer Level Zero packages in system repos that conflict with Intel repo packages
    if is_debian && [[ "$(get_os_version_major)" -ge 13 ]]; then
      # Use system packages on Debian 13+ (avoid conflicts with libze1)
      $STD apt -y install libze1 libze-dev intel-level-zero-gpu 2>/dev/null || {
        msg_warn "Failed to install some Level Zero packages, continuing anyway"
      }
    else
      # Use Intel repository packages for older systems
      $STD apt -y install intel-level-zero-gpu level-zero level-zero-dev 2>/dev/null || {
        msg_warn "Failed to install Intel Level Zero packages, continuing anyway"
      }
    fi
    msg_ok "Installed Intel® Level Zero"

    msg_info "Installing Intel® oneAPI Base Toolkit (Patience)"
    $STD apt install -y --no-install-recommends intel-basekit-2024.1
    msg_ok "Installed Intel® oneAPI Base Toolkit"
    ;;
  esac
done

msg_info "Installing Ollama (Patience)"
OLLAMA_INSTALL_DIR="/usr/local/lib/ollama"
BINDIR="/usr/local/bin"
mkdir -p "$OLLAMA_INSTALL_DIR"
if ! fetch_and_deploy_gh_release "ollama-com" "ollama/ollama" "prebuild" "latest" "$OLLAMA_INSTALL_DIR" "ollama-linux-amd64.tar.zst"; then
  msg_error "Failed to download or deploy Ollama – check network connectivity and GitHub API availability"
  exit 250
fi
ln -sf "$OLLAMA_INSTALL_DIR/bin/ollama" "$BINDIR/ollama"
msg_ok "Installed Ollama"

msg_info "Creating ollama User and Group"
if ! id ollama >/dev/null 2>&1; then
  useradd -r -s /usr/sbin/nologin -U -m -d /usr/share/ollama ollama
fi
$STD usermod -aG ollama $(id -u -n)
msg_ok "Created ollama User and adjusted Groups"

setup_hwaccel "ollama"

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
cleanup_lxc
