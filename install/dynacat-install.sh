#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Panonim/dynacat

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "dynacat" "Panonim/dynacat" "prebuild" "latest" "/opt/dynacat" "dynacat-linux-$(arch_resolve).tar.gz"

msg_info "Setting up Dynacat"
mkdir -p /opt/dynacat/config /opt/dynacat/assets /opt/dynacat/data
chmod +x /opt/dynacat/dynacat

cat <<EOF >/opt/dynacat/config/dynacat.yml
server:
  host: 0.0.0.0
  port: 8080
  assets-path: /opt/dynacat/assets
  db-path: /opt/dynacat/data/dynacat.db

pages:
  - name: Home
    columns:
      - size: small
        widgets:
          - type: calendar
          - type: clock
      - size: full
        widgets:
          - type: search
            search-engine: duckduckgo
          - type: monitor
            title: Services
            sites:
              - title: Dynacat
                url: http://127.0.0.1:8080
            update-interval: 5m
EOF
msg_ok "Set up Dynacat"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/dynacat.service
[Unit]
Description=Dynacat Dashboard
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/dynacat
ExecStart=/opt/dynacat/dynacat -config /opt/dynacat/config/dynacat.yml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now dynacat
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
