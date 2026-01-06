#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://home.tdarr.io/

APP="Tdarr"
var_tags="${var_tags:-arr}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_gpu="${var_gpu:-yes}"

header_info "$APP"
variables
color
catch_errors

# =============================================================================
# NVIDIA Host-Side Configuration
# =============================================================================
# Detect NVIDIA GPU and offer driver pinning to maintain version sync.
# Basic passthrough is handled natively by build.func.

NVIDIA_HOST_VERSION=""
NVIDIA_PIN_HOST="no"

if [ -f /proc/driver/nvidia/version ]; then
    NVIDIA_HOST_VERSION=$(grep "NVRM version:" /proc/driver/nvidia/version | awk '{print $8}')
    if [ -n "$NVIDIA_HOST_VERSION" ]; then
        msg_ok "Detected NVIDIA Host Driver: ${NVIDIA_HOST_VERSION}"
        echo ""
        msg_ok "Driver Pinning prevents automatic driver updates on the host."
        echo "This keeps the host and container in sync, avoiding version mismatch errors."
        read -r -p "Pin NVIDIA driver (${NVIDIA_HOST_VERSION}) on host to prevent updates? <y/N> " prompt
        if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
            NVIDIA_PIN_HOST="yes"
        fi
    fi
elif lspci 2>/dev/null | grep -qi "nvidia"; then
    msg_warn "NVIDIA GPU detected, but host drivers are not installed."
    msg_warn "NVIDIA GPU hardware encoding will not be available in Tdarr without the NVIDIA drivers."
    msg_warn "Intel and AMD hardware encoding support may still be available via /dev/dri."
    echo ""
    read -r -p "Continue without NVIDIA support? (y=continue, n=quit) <y/N> " prompt
    if [[ ! "${prompt,,}" =~ ^(y|yes)$ ]]; then
        msg_info "Aborting. Install NVIDIA drivers on the Proxmox host, then re-run this script."
        exit 0
    fi
fi

if [ "$NVIDIA_PIN_HOST" == "yes" ]; then
    msg_info "Pinning NVIDIA packages on host"
    apt-mark hold nvidia-driver nvidia-kernel-dkms firmware-nvidia-gsp 2>/dev/null || true
    msg_ok "Pinned host NVIDIA packages (use 'apt-mark unhold' to allow updates)"
fi

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/tdarr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating Tdarr"
  $STD apt update
  $STD apt upgrade -y
  rm -rf /opt/tdarr/Tdarr_Updater
  cd /opt/tdarr
  RELEASE=$(curl -fsSL https://f000.backblazeb2.com/file/tdarrs/versions.json | grep -oP '(?<="Tdarr_Updater": ")[^"]+' | grep linux_x64 | head -n 1)
  curl -fsSL "$RELEASE" -o Tdarr_Updater.zip
  $STD unzip Tdarr_Updater.zip
  chmod +x Tdarr_Updater
  $STD ./Tdarr_Updater
  rm -rf /opt/tdarr/Tdarr_Updater.zip
  msg_ok "Updated Tdarr"
  msg_ok "Updated successfully!"
  exit
}

start
build_container


# =============================================================================
# Finalization
# =============================================================================
# Driver detection and passthrough are handled autonomously by build.func
# and the install script.

description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8265${CL}"
