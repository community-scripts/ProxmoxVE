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
msg_ok "Installed Dependencies"

msg_info "Installing Umbrel (Patience)"
DOCKER_CONFIG_PATH='/etc/docker/daemon.json'
mkdir -p $(dirname $DOCKER_CONFIG_PATH)
echo -e '{\n  "log-driver": "journald"\n}' > /etc/docker/daemon.json
$STD bash <(curl -fsSL https://umbrel.sh)
systemctl daemon-reload
$STD systemctl enable --now umbrel-startup.service
msg_ok "Installed Umbrel"

motd_ssh
customize

msg_info "Cleaning up"
#$STD apt-get autoremove
#$STD apt-get autoclean
msg_ok "Cleaned"
