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

# ══════════════════════════════════════════════════════════════════════════════
# GPU Detection - determine which GPU backend to configure
# ══════════════════════════════════════════════════════════════════════════════
GPU_BACKEND="cpu"

if [[ -e /dev/kfd ]]; then
  GPU_BACKEND="rocm"
  msg_ok "Detected AMD GPU (/dev/kfd present) - will configure ROCm backend"
elif [[ -d /dev/dri ]]; then
  # Check if Intel GPU is available (default for this script)
  if lspci 2>/dev/null | grep -iE 'VGA|3D|Display' | grep -qi 'Intel'; then
    GPU_BACKEND="intel"
    msg_ok "Detected Intel GPU - will configure SYCL/oneAPI backend"
  elif [[ -e /dev/dri/renderD128 ]]; then
    GPU_BACKEND="intel"
    msg_ok "Detected GPU (assuming Intel) - will configure SYCL/oneAPI backend"
  fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# Intel GPU Setup
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$GPU_BACKEND" == "intel" ]]; then
  msg_info "Setting up Intel® Repositories"
  mkdir -p /usr/share/keyrings
  curl -fsSL https://repositories.intel.com/gpu/intel-graphics.key | gpg --dearmor -o /usr/share/keyrings/intel-graphics.gpg
  cat <<EOF >/etc/apt/sources.list.d/intel-gpu.sources
Types: deb
URIs: https://repositories.intel.com/gpu/ubuntu
Suites: jammy
Components: client
Architectures: amd64 i386
Signed-By: /usr/share/keyrings/intel-graphics.gpg
EOF
  curl -fsSL https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor -o /usr/share/keyrings/oneapi-archive-keyring.gpg
  cat <<EOF >/etc/apt/sources.list.d/oneAPI.sources
Types: deb
URIs: https://apt.repos.intel.com/oneapi
Suites: all
Components: main
Signed-By: /usr/share/keyrings/oneapi-archive-keyring.gpg
EOF
  $STD apt update
  msg_ok "Set up Intel® Repositories"
fi

setup_hwaccel

# ══════════════════════════════════════════════════════════════════════════════
# Intel-specific: Level Zero + oneAPI
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$GPU_BACKEND" == "intel" ]]; then
  msg_info "Installing Intel® Level Zero"
  if is_debian && [[ "$(get_os_version_major)" -ge 13 ]]; then
    $STD apt -y install libze1 libze-dev intel-level-zero-gpu 2>/dev/null || {
      msg_warn "Failed to install some Level Zero packages, continuing anyway"
    }
  else
    $STD apt -y install intel-level-zero-gpu level-zero level-zero-dev 2>/dev/null || {
      msg_warn "Failed to install Intel Level Zero packages, continuing anyway"
    }
  fi
  msg_ok "Installed Intel® Level Zero"

  msg_info "Installing Intel® oneAPI Base Toolkit (Patience)"
  $STD apt install -y --no-install-recommends intel-basekit-2024.1
  msg_ok "Installed Intel® oneAPI Base Toolkit"
fi

# ══════════════════════════════════════════════════════════════════════════════
# AMD ROCm-specific: ensure ROCm libraries are present for Ollama
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$GPU_BACKEND" == "rocm" ]]; then
  msg_info "Verifying ROCm runtime for Ollama"
  # ROCm base libraries should already be installed by setup_hwaccel -> _setup_amd_gpu
  # Ensure the ollama-relevant pieces are present
  if ! ldconfig -p 2>/dev/null | grep -q libamdhip64; then
    msg_warn "ROCm HIP runtime not found - Ollama may fall back to CPU"
    msg_info "You can manually install ROCm following: https://rocm.docs.amd.com/projects/install-on-linux/en/latest/"
  else
    msg_ok "ROCm HIP runtime available"
  fi
  msg_ok "Verified ROCm runtime"
fi

msg_info "Installing Ollama (Patience)"
RELEASE=$(curl -fsSL https://api.github.com/repos/ollama/ollama/releases/latest | grep "tag_name" | awk -F '"' '{print $4}')
OLLAMA_INSTALL_DIR="/usr/local/lib/ollama"
BINDIR="/usr/local/bin"
mkdir -p $OLLAMA_INSTALL_DIR
OLLAMA_URL="https://github.com/ollama/ollama/releases/download/${RELEASE}/ollama-linux-amd64.tar.zst"
TMP_TAR="/tmp/ollama.tar.zst"
echo -e "\n"
if curl -fL# -C - -o "$TMP_TAR" "$OLLAMA_URL"; then
  if tar --zstd -xf "$TMP_TAR" -C "$OLLAMA_INSTALL_DIR"; then
    ln -sf "$OLLAMA_INSTALL_DIR/bin/ollama" "$BINDIR/ollama"
    echo "${RELEASE}" >/opt/Ollama_version.txt
    msg_ok "Installed Ollama ${RELEASE}"
  else
    msg_error "Extraction failed – archive corrupt or incomplete"
    exit 251
  fi
else
  msg_error "Download failed – $OLLAMA_URL not reachable"
  exit 250
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
Environment=OLLAMA_HOST=0.0.0.0
Environment=OLLAMA_NUM_GPU=999
EOF

# Add GPU-specific environment variables
if [[ "$GPU_BACKEND" == "intel" ]]; then
  cat <<EOF >>/etc/systemd/system/ollama.service
Environment=OLLAMA_INTEL_GPU=true
Environment=SYCL_CACHE_PERSISTENT=1
Environment=ZES_ENABLE_SYSMAN=1
EOF
elif [[ "$GPU_BACKEND" == "rocm" ]]; then
  cat <<EOF >>/etc/systemd/system/ollama.service
Environment=HSA_OVERRIDE_GFX_VERSION=11.0.0
EOF
fi

cat <<EOF >>/etc/systemd/system/ollama.service
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
