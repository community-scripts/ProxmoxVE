#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Jonathan (jd-apprentice)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y jq
$STD apt-get install -y sudo
$STD apt-get install -y git
msg_ok "Installed Dependencies"

msg_info "Download Opengist Binary"
LATEST_URL=$(curl -s https://api.github.com/repos/thomiceli/opengist/releases/latest | jq -r '.assets[] | select(.name | contains("linux-amd64.tar.gz")).browser_download_url')
wget "$LATEST_URL"
msg_ok "Downloaded Opengist Binary"

msg_info "Creating Systemd Service"
mkdir -p /opt/opengist
mv opengist*.tar.gz opengist.tar.gz
tar -xf opengist.tar.gz
mv opengist/opengist /opt/opengist/opengist
mv opengist/config.yml /opt/opengist/config.yml
chmod +x /opt/opengist/opengist
rm -rf opengist*
cat <<EOF >/etc/systemd/system/opengist.service
[Unit]
Description=Opengist server to manage your Gists
After=network.target

[Service]
WorkingDirectory=/opt/opengist
ExecStart=/opt/opengist/opengist
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
msg_ok "Created Systemd Service"

msg_info "Starting Service"
systemctl daemon-reload
systemctl enable -q --now opengist.service
msg_ok "Started Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
