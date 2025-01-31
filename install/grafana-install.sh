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
$STD apt-get install -y gnupg
$STD apt-get install -y apt-transport-https
$STD apt-get install -y software-properties-common
msg_ok "Installed Dependencies"

msg_info "Setting up Grafana Repository"
wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
sh -c 'echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list'
msg_ok "Set up Grafana Repository"

msg_info "Installing Grafana"
$STD apt-get update
$STD apt-get install -y grafana
systemctl start grafana-server
systemctl enable --now -q grafana-server.service
msg_ok "Installed Grafana"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
