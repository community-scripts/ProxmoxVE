#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pterodactyl/wings

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
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
  mc
msg_ok "Installed Dependencies"

msg_info "Installing Docker"
DOCKER_CONFIG_PATH='/etc/docker/daemon.json'
mkdir -p $(dirname $DOCKER_CONFIG_PATH)
echo -e '{\n  "log-driver": "journald"\n}' >/etc/docker/daemon.json
$STD sh <(curl -sSL https://get.docker.com)
systemctl enable -q --now docker
msg_ok "Installed Docker"

msg_info "Installing Pterodactyl Wings"
RELEASE=$(curl -s https://api.github.com/repos/pterodactyl/wings/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q -O /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/download/v${RELEASE}/wings_linux_amd64"
chmod u+x /usr/local/bin/wings
mkdir -p /etc/pterodactyl
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed Pterodactyl Wings"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/wings.service
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now wings
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
