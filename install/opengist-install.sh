#!/usr/bin/env bash

# Copyright (c) 2021-2025 Jonathan
# Author: Jonathan (jd-apprentice)
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
$STD apt-get install -y jq
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y gnupg
$STD apt-get install -y apt-transport-https
msg_ok "Installed Dependencies"

msg_info "Download Opengist Binary"
LATEST_URL=$(curl -s https://api.github.com/repos/thomiceli/opengist/releases/latest | jq -r '.assets[] | select(.name | contains("linux-amd64.tar.gz")).browser_download_url')
wget "$LATEST_URL"
msg_ok "Downloaded Opengist Binary"

msg_info "Creating Systemd Service"
mv opengist*.tar.gz opengist.tar.gz
tar -xf opengist.tar.gz
mv opengist /usr/local/bin
chmod +x /usr/local/bin/opengist
rm -rf opengist.tar.gz
cat <<EOF >/etc/systemd/system/opengist.service
[Unit]
Description=Opengist server to manage your Gists
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/opengist
ExecStart=/usr/local/bin/opengist
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

msg_info "Starting Service"
systemctl daemon-reload
systemctl enable -q --now opengist.service
msg_ok ""

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
