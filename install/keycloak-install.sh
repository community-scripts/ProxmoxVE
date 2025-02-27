#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: tteck (tteckster) | Co-Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/keycloak/keycloak

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
curl \
sudo \
mc \
gnupg
msg_ok "Installed Dependencies"

msg_info "Installing OpenJDK"
wget -qO- https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor >/etc/apt/trusted.gpg.d/adoptium.gpg
echo 'deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/adoptium.gpg] https://packages.adoptium.net/artifactory/deb bookworm main' >/etc/apt/sources.list.d/adoptium.list
$STD apt-get update
$STD apt-get install -y temurin-21-jre
msg_ok "Installed OpenJDK"

msg_info "Installing Keycloak"
temp_file=$(mktemp)
RELEASE=$(curl -s https://api.github.com/repos/keycloak/keycloak/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
wget -q https://github.com/keycloak/keycloak/releases/download/$RELEASE/keycloak-$RELEASE.tar.gz -O $temp_file
tar xzf $temp_file
mv keycloak-$RELEASE /opt/keycloak
msg_ok "Installed Keycloak"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/keycloak.service
[Unit]
Description=Keycloak Service
After=network.target

[Service]
User=root
WorkingDirectory=/opt/keycloak
ExecStart=/opt/keycloak/bin/kc.sh start-dev

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now keycloak
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f $temp_file
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
