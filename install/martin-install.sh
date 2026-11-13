#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/maplibre/martin

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "martin" "maplibre/martin" "prebuild" "latest" "/opt/martin" "martin-$(arch_resolve "x86_64" "aarch64")-unknown-linux-musl.tar.gz"

msg_info "Configuring Martin"
mkdir -p /opt/martin_data/tiles
cat <<EOF >/opt/martin_data/config.yaml
listen_addresses: 0.0.0.0:3000
web_ui: enable-for-all

mbtiles:
  paths:
    - /opt/martin_data/tiles

pmtiles:
  paths:
    - /opt/martin_data/tiles

# postgres:
#   connection_string: postgres://user:password@host:5432/database
EOF
msg_ok "Configured Martin"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/martin.service
[Unit]
Description=Martin Tile Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/martin_data
ExecStart=/opt/martin/martin --config /opt/martin_data/config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now martin
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
