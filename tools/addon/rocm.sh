#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: community-scripts
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://rocm.docs.amd.com

# ==============================================================================
# ROCm ADDON - AMD ROCm Installation for Debian/Ubuntu LXC Containers
# Supports: Debian 12, Debian 13, Ubuntu 22.04, Ubuntu 24.04
# ==============================================================================

ensure_dependencies curl

source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/error_handler.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/install.func)

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR
load_functions
init_tool_telemetry "" "addon"

function header_info {
  clear
  cat <<"EOF"
    ____  ____  ________  ___
   / __ \/ __ \/ ____/  |/  /
  / /_/ / / / / /   / /|_/ /
 / _, _/ /_/ / /___/ /  / /
/_/ |_|\____/\____/_/  /_/

ROCM Installer for Proxmox LXC Containers

EOF
}

# ==============================================================================
# ROCm REPOSITORY MAPPING
# ==============================================================================
# Sets ROCm-specific variables based on OS detection from install.func
# Variables set: OS, OS_CODENAME, ROCM_REPO_CODENAME, ROCM_VERSION
# Requires: OS_TYPE and OS_VERSION from detect_os() in install.func
# ==============================================================================
function setup_rocm_repo_mapping() {
  ROCM_VERSION="7.2"

  case "${OS_TYPE}" in
    debian)
      OS="Debian"
      case "${OS_VERSION}" in
        12)
          OS_CODENAME="bookworm"
          ROCM_REPO_CODENAME="jammy"
          ;;
        13)
          OS_CODENAME="trixie"
          ROCM_REPO_CODENAME="noble"
          ;;
        *)
          msg_error "Unsupported Debian version: ${OS_VERSION}"
          msg_info "Supported versions: Debian 12, Debian 13"
          exit 1
          ;;
      esac
      ;;
    ubuntu)
      OS="Ubuntu"
      case "${OS_VERSION}" in
        22.04)
          OS_CODENAME="jammy"
          ROCM_REPO_CODENAME="jammy"
          ;;
        24.04)
          OS_CODENAME="noble"
          ROCM_REPO_CODENAME="noble"
          ;;
        *)
          msg_error "Unsupported Ubuntu version: ${OS_VERSION}"
          msg_info "Supported versions: Ubuntu 22.04, Ubuntu 24.04"
          exit 1
          ;;
      esac
      ;;
    *)
      msg_error "Unsupported OS: ${OS_TYPE}"
      msg_info "Supported OS: Debian 12, Debian 13, Ubuntu 22.04, Ubuntu 24.04"
      exit 1
      ;;
  esac

  msg_ok "Detected: ${OS} ${OS_VERSION} (${OS_CODENAME})"
}

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================
function check_lxc() {
  if [[ -f "/proc/1/cgroup" ]] && grep -q "lxc" /proc/1/cgroup 2>/dev/null; then
    return 0
  fi
  if grep -q "container=lxc" /proc/1/environ 2>/dev/null; then
    return 0
  fi
  return 1
}

# ==============================================================================
# INSTALL FUNCTIONS
# ==============================================================================
function install_rocm_debian() {
  msg_info "Adding ROCm repository GPG key"
  if ! download_gpg_key "https://repo.radeon.com/rocm/rocm.gpg.key" "/etc/apt/keyrings/rocm.gpg" "dearmor"; then
    msg_error "Failed to download or import ROCm GPG key"
    exit 1
  fi
  msg_ok "Added ROCm GPG key"

  msg_info "Adding ROCm repository (using ${ROCM_REPO_CODENAME} for ${OS} ${OS_VERSION})"
  # Use deb822 format (new standard, replaces deprecated .list format)
  cat <<EOF >/etc/apt/sources.list.d/rocm.sources
Types: deb
URIs: https://repo.radeon.com/rocm/apt/${ROCM_VERSION}
Suites: ${ROCM_REPO_CODENAME}
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/rocm.gpg

Types: deb
URIs: https://repo.radeon.com/graphics/${ROCM_VERSION}/ubuntu
Suites: ${ROCM_REPO_CODENAME}
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/rocm.gpg
EOF
  msg_ok "Added ROCm repository"

  msg_info "Setting package pin preferences"
  cat <<EOF >/etc/apt/preferences.d/rocm-pin-600
Package: *
Pin: release o=repo.radeon.com
Pin-Priority: 600
EOF
  msg_ok "Set package pin preferences"

  msg_info "Updating package lists"
  $STD apt update
  msg_ok "Updated package lists"

  msg_info "Installing ROCm packages"
  $STD apt install -y rocm
  msg_ok "Installed ROCm packages"

  msg_info "Adding user to render and video groups"
  usermod -aG render,video root
  for user_home in /home/*/; do
    [[ -d "$user_home" ]] || continue
    user=$(basename "$user_home")
    usermod -aG render,video "$user" 2>/dev/null || true
  done
  msg_ok "Added users to render and video groups"

  msg_info "Configuring /dev/kfd permissions"
  if [[ -e /dev/kfd ]]; then
    chgrp render /dev/kfd 2>/dev/null || true
    chmod 660 /dev/kfd
    msg_ok "Configured /dev/kfd permissions"
  else
    msg_warn "/dev/kfd not found - GPU passthrough may not be configured"
  fi

  msg_info "Configuring environment"
  cat <<EOF >/etc/profile.d/rocm.sh
export PATH=\$PATH:/opt/rocm/bin
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/opt/rocm/lib
EOF
  chmod +x /etc/profile.d/rocm.sh
  msg_ok "Configured environment"
}

function install_rocm_ubuntu() {
  msg_info "Adding ROCm repository GPG key"
  if ! download_gpg_key "https://repo.radeon.com/rocm/rocm.gpg.key" "/etc/apt/keyrings/rocm.gpg" "dearmor"; then
    msg_error "Failed to download or import ROCm GPG key"
    exit 1
  fi
  msg_ok "Added ROCm GPG key"

  msg_info "Adding ROCm repository"
  # Use deb822 format (new standard, replaces deprecated .list format)
  cat <<EOF >/etc/apt/sources.list.d/rocm.sources
Types: deb
URIs: https://repo.radeon.com/rocm/apt/${ROCM_VERSION}
Suites: ${ROCM_REPO_CODENAME}
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/rocm.gpg

Types: deb
URIs: https://repo.radeon.com/graphics/${ROCM_VERSION}/ubuntu
Suites: ${ROCM_REPO_CODENAME}
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/rocm.gpg
EOF
  msg_ok "Added ROCm repository"

  msg_info "Setting package pin preferences"
  cat <<EOF >/etc/apt/preferences.d/rocm-pin-600
Package: *
Pin: release o=repo.radeon.com
Pin-Priority: 600
EOF
  msg_ok "Set package pin preferences"

  msg_info "Updating package lists"
  $STD apt update
  msg_ok "Updated package lists"

  msg_info "Installing ROCm packages"
  $STD apt install -y rocm
  msg_ok "Installed ROCm packages"

  msg_info "Adding user to render and video groups"
  usermod -aG render,video root
  for user_home in /home/*/; do
    [[ -d "$user_home" ]] || continue
    user=$(basename "$user_home")
    usermod -aG render,video "$user" 2>/dev/null || true
  done
  msg_ok "Added users to render and video groups"

  msg_info "Configuring /dev/kfd permissions"
  if [[ -e /dev/kfd ]]; then
    chgrp render /dev/kfd 2>/dev/null || true
    chmod 660 /dev/kfd
    msg_ok "Configured /dev/kfd permissions"
  else
    msg_warn "/dev/kfd not found - GPU passthrough may not be configured"
  fi

  msg_info "Configuring environment"
  cat <<EOF >/etc/profile.d/rocm.sh
export PATH=\$PATH:/opt/rocm/bin
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/opt/rocm/lib
EOF
  chmod +x /etc/profile.d/rocm.sh
  msg_ok "Configured environment"
}

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall_rocm() {
  msg_info "Uninstalling ROCm"

  msg_info "Removing ROCm packages"
  $STD apt remove -y rocm
  $STD apt autoremove -y
  msg_ok "Removed ROCm packages"

  msg_info "Removing ROCm repository and keyring"
  # Remove both old .list and new .sources formats
  rm -f /etc/apt/sources.list.d/rocm.list
  rm -f /etc/apt/sources.list.d/rocm.sources
  rm -f /etc/apt/preferences.d/rocm-pin-600
  cleanup_tool_keyrings "rocm"
  $STD apt update
  msg_ok "Removed ROCm repository"

  msg_info "Removing environment configuration"
  rm -f /etc/profile.d/rocm.sh
  msg_ok "Removed environment configuration"

  msg_ok "ROCm has been uninstalled"
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update_rocm() {
  if [[ ! -f /etc/apt/keyrings/rocm.gpg ]]; then
    msg_error "ROCm is not installed"
    exit 1
  fi

  msg_info "Checking for ROCm updates"
  $STD apt update

  local updates
  updates=$(apt list --upgradable 2>/dev/null | grep -c "rocm" || true)

  if [[ "$updates" -gt 0 ]]; then
    msg_ok "Found ${updates} ROCm package update(s)"
    msg_info "Upgrading ROCm packages"
    $STD apt install --only-upgrade rocm
    msg_ok "Updated ROCm packages"
  else
    msg_ok "ROCm is already up-to-date"
  fi
}

# ==============================================================================
# VERIFY INSTALLATION
# ==============================================================================
function verify_installation() {
  msg_info "Verifying ROCm installation"

  if [[ -x /opt/rocm/bin/rocminfo ]]; then
    msg_ok "ROCm installed successfully"
    echo ""
    echo -e "${TAB}${BL}ROCm Version:${CL} $(/opt/rocm/bin/rocminfo --version 2>/dev/null | head -1 || echo 'Installed')"
    echo -e "${TAB}${BL}Install Path:${CL} /opt/rocm"
    echo ""
    echo -e "${TAB}${YW}To use ROCm, either:${CL}"
    echo -e "${TAB}  1. Log out and back in, or"
    echo -e "${TAB}  2. Run: source /etc/profile.d/rocm.sh"
    echo ""
    echo -e "${TAB}${YW}Verify installation with:${CL}"
    echo -e "${TAB}  rocminfo"
    echo -e "${TAB}  rocm-smi"
  else
    msg_warn "ROCm installed but rocminfo not found. GPU may not be available."
  fi
}

# ==============================================================================
# MAIN
# ==============================================================================
header_info

# Use detect_os from install.func (sets OS_TYPE, OS_VERSION, OS_FAMILY, etc.)
detect_os

# Set up ROCm-specific variables based on OS detection
setup_rocm_repo_mapping

# Use get_lxc_ip from core.func (sets LOCAL_IP environment variable)
get_lxc_ip

# Check if running in LXC container
if ! check_lxc; then
  msg_warn "This script is designed for LXC containers."
  msg_warn "Running on bare metal may work but is not officially supported."
  echo ""
fi

# Check for existing installation
if [[ -f /etc/apt/keyrings/rocm.gpg ]]; then
  msg_warn "ROCm is already installed."
  echo ""

  echo -n "${TAB}Uninstall ROCm? (y/N): "
  read -r uninstall_prompt
  if [[ "${uninstall_prompt,,}" =~ ^(y|yes)$ ]]; then
    uninstall_rocm
    exit 0
  fi

  echo -n "${TAB}Update ROCm? (y/N): "
  read -r update_prompt
  if [[ "${update_prompt,,}" =~ ^(y|yes)$ ]]; then
    update_rocm
    exit 0
  fi

  msg_warn "No action selected. Exiting."
  exit 0
fi

# Fresh installation
msg_warn "ROCm is not installed."
echo ""

echo -e "${TAB}${BL}This will install AMD ROCm on ${OS} ${OS_VERSION}${CL}"
echo -e "${TAB}${BL}Supported GPUs: AMD Radeon Instinct, Radeon Pro, and some consumer GPUs${CL}"
echo ""

echo -n "${TAB}Install ROCm? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  case "${OS}" in
    Debian) install_rocm_debian ;;
    Ubuntu) install_rocm_ubuntu ;;
    *)
      msg_error "Unsupported OS: ${OS}"
      exit 1
      ;;
  esac

  verify_installation

  echo ""
  msg_ok "ROCm installation completed!"
  echo -e "${TAB}${GN}Documentation: ${BL}https://rocm.docs.amd.com${CL}"
else
  msg_warn "Installation cancelled. Exiting."
  exit 0
fi
