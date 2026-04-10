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
nameservers=$(grep '^nameserver' /etc/resolv.conf | awk '{print $2}' | xargs)
curl -fsSL "https://packages.openmediavault.org/public/archive.key" | gpg --dearmor >"/etc/apt/trusted.gpg.d/openmediavault-archive-keyring.gpg"
echo "deb [signed-by=/etc/apt/trusted.gpg.d/openmediavault-archive-keyring.gpg] http://packages.openmediavault.org/public synchrony main" >/etc/apt/sources.list.d/openmediavault.list
export APT_LISTCHANGES_FRONTEND=none
export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8
$STD apt update
$STD apt install -y openmediavault openmediavault-keyring \
  --allow-change-held-packages \
  --allow-downgrades \
  --auto-remove \
  --no-install-recommends
msg_ok "Installed OpenMediaVault"

msg_info "Configuring OpenMediaVault (patience)"
$STD omv-confdbadm populate
sed -i "s/^#\?DNS=.*/DNS=$nameservers/" /etc/systemd/resolved.conf
$STD systemctl restart systemd-resolved
$STD apt update
msg_ok "Configured OpenMediaVault index"

echo
read -r -p "${TAB3}Would you like to add plugins from OMV-extras repository? [y/N]: " CONFIRM
echo
if [[ "$CONFIRM" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  msg_warn "WARNING: This script will run an external installer from a third-party source (https://wiki.omv-extras.org/)."
  msg_warn "The following code is NOT maintained or audited by our repository."
  msg_warn "If you have any doubts or concerns, please review the installer code before proceeding:"
  msg_custom "${TAB3}${GATEWAY}${BGN}${CL}" "\e[1;34m" "→  https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/install"
  echo
  read -r -p "${TAB3}Do you want to continue? [y/N]: " CONFIRM
  echo
  if [[ "$CONFIRM" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    msg_info "Installing OMV extras"
    $STD bash <(curl -fsSL https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/install)
    msg_ok "Installed OMV extras"
  else
    msg_error "Aborted by user. No changes have been made."
  fi
fi

motd_ssh
customize
cleanup_lxc
