#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: Proxmox Server Solution GmbH

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y rsyslog
systemctl enable -q --now rsyslog
msg_ok "Installed Dependencies"

msg_info "Installing Proxmox Datacenter Manager"
curl -fsSL https://enterprise.proxmox.com/debian/proxmox-archive-keyring-trixie.gpg -o /usr/share/keyrings/proxmox-archive-keyring.gpg
setup_deb822_repo \
  "pdm" \
  "https://enterprise.proxmox.com/debian/proxmox-archive-keyring-trixie.gpg" \
  "http://download.proxmox.com/debian/pdm" \
  "trixie" \
  "pdm-no-subscription"

setup_deb822_repo \
  "pdm-test" \
  "https://enterprise.proxmox.com/debian/proxmox-archive-keyring-trixie.gpg" \
  "http://download.proxmox.com/debian/pdm" \
  "trixie" \
  "pdm-test" \
  "" \
  "false"

cat <<'EOF' > /etc/apt/preferences.d/99-pdm-unneeded-packages
Package: proxmox-default-kernel proxmox-kernel-* pve-firmware
Pin: release *
Pin-Priority: -1
EOF

DEBIAN_FRONTEND=noninteractive
$STD apt -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  install -y proxmox-datacenter-manager \
  proxmox-mail-forward \
  proxmox-offline-mirror-helper
msg_ok "Installed Proxmox Datacenter Manager"

motd_ssh
customize
cleanup_lxc
