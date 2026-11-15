#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: mews-se
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://dietpi.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_warn "WARNING: This script will run an external installer from a third-party source (https://dietpi.com/)."
msg_warn "The following code is NOT maintained or audited by our repository."
msg_warn "If you have any doubts or concerns, please review the installer code before proceeding:"
msg_custom "${TAB3}${GATEWAY}${BGN}${CL}" "\e[1;34m" "→  https://raw.githubusercontent.com/MichaIng/DietPi/master/.build/images/dietpi-installer"
echo
if ! prompt_confirm "${TAB3}Do you want to continue?" "y" 60; then
  msg_error "Aborted by user. No changes have been made."
  exit 10
fi

motd_ssh

msg_info "Converting Debian to DietPi"
curl -fsSL https://raw.githubusercontent.com/MichaIng/DietPi/master/.build/images/dietpi-installer -o /tmp/dietpi-installer
$STD env G_INTERACTIVE=0 GITBRANCH=master HW_MODEL=75 DISTRO_TARGET=8 GUEST_NETWORK_REQUIRED=1 IMAGE_CREATOR=community-scripts PREIMAGE_INFO='Proxmox Debian LXC template' bash /tmp/dietpi-installer
rm -f /tmp/dietpi-installer
msg_ok "Converted Debian to DietPi"

msg_info "Configuring DietPi"
sed -i -e 's/^AUTO_SETUP_NET_ETHERNET_ENABLED=.*/AUTO_SETUP_NET_ETHERNET_ENABLED=0/' \
  -e "s/^AUTO_SETUP_NET_HOSTNAME=.*/AUTO_SETUP_NET_HOSTNAME=$(hostname)/" /boot/dietpi.txt
if [[ -n "${PASSWORD:-}" ]]; then
  sed -i '/^AUTO_SETUP_GLOBAL_PASSWORD=/d' /boot/dietpi.txt
  echo "AUTO_SETUP_GLOBAL_PASSWORD=$PASSWORD" >>/boot/dietpi.txt
fi
rm -f /etc/apt/sources.list.d/debian.sources
rm -f /etc/sysctl.d/97-dietpi.conf
rm -f /etc/systemd/system/local-fs.target.wants/dietpi-fs_partition_resize.service
msg_ok "Configured DietPi"

customize
# Autologin on tty1 only: DietPi's first run setup runs on the first console that logs in, and the Proxmox UI attaches to tty1
rm -f /etc/systemd/system/console-getty.service.d/override.conf
if [[ -f /etc/systemd/system/container-getty@.service.d/override.conf ]]; then
  mkdir -p /etc/systemd/system/container-getty@1.service.d
  mv /etc/systemd/system/container-getty@.service.d/override.conf /etc/systemd/system/container-getty@1.service.d/
  rmdir /etc/systemd/system/container-getty@.service.d
fi
cleanup_lxc
