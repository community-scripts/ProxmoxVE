#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://release-argus.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "Argus" "release-argus/Argus" "singlefile" "latest" "/opt/argus" "Argus*linux-amd64"

msg_info "Setup Argus Config"
cat <<EOF >/opt/argus/config.yml
settings:
  log:
    level: INFO
    timestamps: false
  data:
    database_file: data/argus.db
  web:
    listen_host: 0.0.0.0
    listen_port: 8080
    route_prefix: /

defaults:
  service:
    options:
      interval: 30m
      semantic_versioning: true
    latest_version:
      allow_invalid_certs: false
      use_prerelease: false
    dashboard:
      auto_approve: true
  webhook:
    desired_status_code: 201

service:
  release-argus/argus:
    latest_version:
      type: github
      url: release-argus/argus
    dashboard:
      icon: https://raw.githubusercontent.com/release-argus/Argus/master/web/ui/react-app/public/favicon.svg
      icon_link_to: https://release-argus.io
      web_url: https://github.com/release-argus/Argus/blob/master/CHANGELOG.md

  community-scripts/ProxmoxVE:
    latest_version:
      type: github
      url: community-scripts/ProxmoxVE
      use_prerelease: false
    dashboard:
      icon: https://raw.githubusercontent.com/community-scripts/ProxmoxVE/refs/heads/main/misc/images/logo.png
      icon_link_to: https://helper-scripts.com/
      web_url: https://github.com/community-scripts/ProxmoxVE/releases
EOF
msg_ok "Setup Config"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/argus.service
[Unit]
Description=Argus
After=network.target
[Service]
Type=simple
WorkingDirectory=/opt/argus
ExecStart=/opt/argus/Argus
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now argus
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
