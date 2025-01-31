#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y gpg
msg_ok "Installed Dependencies"

msg_info "Installing OpenMediaVault (Patience)"
wget -qO- https://packages.openmediavault.org/public/archive.key | gpg --dearmor >"/etc/apt/trusted.gpg.d/openmediavault-archive-keyring.gpg"

cat <<EOF >/etc/apt/sources.list.d/openmediavault.list
deb [signed-by=/etc/apt/trusted.gpg.d/openmediavault-archive-keyring.gpg] http://packages.openmediavault.org/public sandworm main
EOF

export LANG=C.UTF-8
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
$STD apt-get update
apt-get -y --auto-remove --show-upgraded --allow-downgrades --allow-change-held-packages --no-install-recommends --option DPkg::Options::="--force-confdef" --option DPkg::Options::="--force-confold" install openmediavault-keyring openmediavault &>/dev/null
omv-confdbadm populate &>/dev/null
msg_ok "Installed OpenMediaVault"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
