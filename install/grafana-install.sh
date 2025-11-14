#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://grafana.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  apt-transport-https \
  software-properties-common
msg_ok "Installed Dependencies"

msg_info "Setting up Grafana Repository"
curl -fsSL "https://apt.grafana.com/gpg.key" -o "/usr/share/keyrings/grafana.key"
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" >/etc/apt/sources.list.d/grafana.list
msg_ok "Set up Grafana Repository"

msg_info "Installing Grafana"
$STD apt update
$STD apt install -y grafana
systemctl enable -q --now grafana-server
msg_ok "Installed Grafana"

motd_ssh
customize
cleanup_lxc
