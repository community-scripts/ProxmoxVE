#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: kristocopani
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/glanceapp/glance

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "glance" "glanceapp/glance" "prebuild" "latest" "/opt/glance" "glance-linux-amd64.tar.gz"

msg_info "Configuring Glance"
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
msg_ok "Configured Glance"

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

systemctl enable -q --now glance
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
