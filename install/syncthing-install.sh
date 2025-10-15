#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://syncthing.net/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Setting up Syncthing repo"
mkdir -p /usr/share/keyrings
curl -fsSL "https://syncthing.net/release-key.gpg" -o /usr/share/keyrings/syncthing-archive-keyring.gpg
cat <<EOF >/etc/apt/sources.list.d/syncthing.sources
Types: deb
URIs: https://apt.syncthing.net/
Suites: syncthing
Components: stable-v2
Signed-By: /usr/share/keyrings/syncthing-archive-keyring.gpg
EOF
$STD apt update
msg_ok "Set up Syncthing repo"

msg_info "Installing Syncthing"
$STD apt install -y syncthing
systemctl enable -q --now syncthing@root
sleep 5
sed -i "{s/127.0.0.1:8384/0.0.0.0:8384/g}" /root/.local/state/syncthing/config.xml
systemctl restart syncthing@root
msg_ok "Installed Syncthing"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
