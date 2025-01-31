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

msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y ca-certificates-java
$STD apt-get install -y openjdk-17-jre-headless
msg_ok "Installed Dependencies"

RELEASE=$(curl -s https://api.github.com/repos/keycloak/keycloak/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
msg_info "Installing Keycloak v$RELEASE"
cd /opt
wget -q https://github.com/keycloak/keycloak/releases/download/$RELEASE/keycloak-$RELEASE.tar.gz
$STD tar -xvf keycloak-$RELEASE.tar.gz
mv keycloak-$RELEASE keycloak
msg_ok "Installed Keycloak"

msg_info "Creating Service"
service_path="/etc/systemd/system/keycloak.service"
echo "[Unit]
Description=Keycloak
After=network-online.target
[Service]
User=root
WorkingDirectory=/opt/keycloak
ExecStart=/opt/keycloak/bin/kc.sh start-dev
[Install]
WantedBy=multi-user.target" >$service_path
$STD systemctl enable --now keycloak.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
