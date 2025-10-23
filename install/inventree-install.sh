#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/inventree/InvenTree

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Detecting Distro"
DISTRO_OS=$(awk -F= '/^ID=/{print $2}' /etc/os-release)
DISTRO_VER=$(awk -F= '/^VERSION_ID=/{print $2}' /etc/os-release | tr -d '"')

case "$DISTRO_OS" in
debian)
  if [[ "$DISTRO_VER" == "12" ]]; then
    DISTRO_VER="11"
  fi
  ;;
ubuntu)
  if [[ "$DISTRO_VER" == "22.04" ]]; then
    DISTRO_VER="20.04"
    NEEDS_LIBSSL1_1=true
  fi
  ;;
esac
msg_ok "Detected $DISTRO_OS $DISTRO_VER"

msg_info "Installing Dependencies"
if [[ "${NEEDS_LIBSSL1_1:-false}" == "true" ]]; then
  echo "deb http://security.ubuntu.com/ubuntu focal-security main" >/etc/apt/sources.list.d/focal-security.list
  $STD apt update
  $STD apt install -y libssl1.1
  rm -f /etc/apt/sources.list.d/focal-security.list
fi
msg_ok "Installed Dependencies"

msg_info "Setting up InvenTree Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://dl.packager.io/srv/inventree/InvenTree/key | gpg --dearmor -o /etc/apt/keyrings/inventree.gpg
echo "deb [signed-by=/etc/apt/keyrings/inventree.gpg] https://dl.packager.io/srv/deb/inventree/InvenTree/stable/${DISTRO_OS} ${DISTRO_VER} main" \
  >/etc/apt/sources.list.d/inventree.list
$STD apt update
msg_ok "Set up InvenTree Repository"

msg_info "Installing InvenTree"
$STD apt install -y inventree || msg_error "Failed to install InvenTree"
msg_ok "Installed InvenTree"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
