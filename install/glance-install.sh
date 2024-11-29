#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: kristocopani
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
$STD apt-get install -y \
    curl \
    sudo \
    mc 
msg_ok "Installed Dependencies"


msg_info "Installing Glance"
RELEASE=$(curl -s https://api.github.com/repos/glanceapp/glance/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
cd /opt
wget -q https://github.com/glanceapp/glance/releases/download/v${RELEASE}/glance-linux-amd64.tar.gz
mkdir -p /opt/glance
tar -xzf glance-linux-amd64.tar.gz -C /opt/glance
cat <<EOF >/opt/glance/glance.yml
pages:
  - name: Startpage
    width: slim
    hide-desktop-navigation: true
    center-vertically: true
    columns:
      - size: full
        widgets:
          - type: search
            autofocus: true
          - type: bookmarks
            groups:
              - title: General
                links:
                  - title: Google
                    url: https://www.google.com/
                  - title: Helper Scripts
                    url: https://github.com/community-scripts/ProxmoxVE
EOF

echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed Glance"

msg_info "Creating Service"
service_path="/etc/systemd/system/glance.service"
echo "[Unit]
Description=Glance Daemon
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/glance
ExecStart=/opt/glance/glance --config /opt/glance/glance.yml
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target" >$service_path

systemctl enable -q --now glance.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/glance-linux-amd64.tar.gz
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"