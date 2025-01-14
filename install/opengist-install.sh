#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Jonathan (jd-apprentice)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
    mc \
    curl \
    sudo \
    git
msg_ok "Installed Dependencies"

msg_info "Install Opengist"
RELEASE=$(curl -s https://api.github.com/repos/thomiceli/opengist/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
wget -q "https://github.com/thomiceli/opengist/releases/download/v${RELEASE}/opengist${RELEASE}-linux-amd64.tar.gz"
$STD tar -xzf opengist${RELEASE}-linux-amd64.tar.gz
mv opengist /opt/opengist
chmod +x /opt/opengist/opengist
mkdir -p /opt/opengist-data
msg_ok "Installed Opengist"

msg_info "Creating Service"

sed -i 's|opengist-home:.*|opengist-home: /opt/opengist-data|' /opt/opengist/config.yml

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
systemctl enable -q --now opengist.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opengist${RELEASE}-linux-amd64.tar.gz
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
