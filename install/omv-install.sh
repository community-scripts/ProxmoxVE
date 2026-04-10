#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.openmediavault.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing OpenMediaVault (patience)"
curl -fsSL "https://packages.openmediavault.org/public/archive.key" | gpg --dearmor >"/etc/apt/trusted.gpg.d/openmediavault-archive-keyring.gpg"
echo "deb [signed-by=/etc/apt/trusted.gpg.d/openmediavault-archive-keyring.gpg] http://packages.openmediavault.org/public synchrony main" >/etc/apt/sources.list.d/openmediavault.list
$STD apt update
export LANG=C.UTF-8
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
apt install -y openmediavault-keyring openmediavault \
  --allow-change-held-packages \
  --allow-downgrades \
  --auto-remove \
  --no-install-recommends \
  --option DPkg::Options::="--force-confdef" \
  --option DPkg::Options::="--force-confold" \
  --show-upgraded \
  &>/dev/null
omv-confdbadm populate &>/dev/null
(systemctl restart networking &) &>/dev/null
msg_ok "Installed OpenMediaVault"

msg_info "Regenerating OpenMediaVault index (patience)"
timeout 300s bash -c "until ping -c1 -W1 community-scripts.org &>/dev/null; do sleep 1; done"
$STD apt update
msg_ok "Regenerated OpenMediaVault index"

if whiptail --title "Customize OMV" --yesno "Would you like to add OMV extras?" 8 60; then
  msg_info "Installing OMV extras"
  $STD bash <(curl -fsSL https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/install)
  rm -f /var/lib/dpkg/lock
  msg_ok "Installed OMV extras"
fi

motd_ssh
customize
cleanup_lxc
