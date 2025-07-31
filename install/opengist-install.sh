#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Jonathan (jd-apprentice)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://opengist.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y git
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "opengist" "thomiceli/opengist" "prebuild" "latest" "/opt/opengist" "opengist*linux-amd64.tar.gz"
mkdir -p /opt/opengist-data
sed -i 's|opengist-home:.*|opengist-home: /opt/opengist-data|' /opt/opengist/config.yml

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/opengist.service
[Unit]
Description=Opengist server to manage your Gists
After=network.target

[Service]
WorkingDirectory=/opt/opengist
ExecStart=/opt/opengist/opengist --config /opt/opengist/config.yml
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now opengist
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
