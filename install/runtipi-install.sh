#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://runtipi.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Runtipi (Patience)"
DOCKER_CONFIG_PATH='/etc/docker/daemon.json'
mkdir -p "$(dirname "$DOCKER_CONFIG_PATH")"
echo -e '{\n  "log-driver": "journald"\n}' >"$DOCKER_CONFIG_PATH"
cd /opt
curl -fsSL "https://raw.githubusercontent.com/runtipi/runtipi/master/scripts/install.sh" -o "install.sh"
chmod +x install.sh
$STD ./install.sh
chmod 666 /opt/runtipi/state/settings.json
msg_ok "Installed Runtipi"

motd_ssh
customize

msg_info "Cleaning up"
rm /opt/install.sh
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
