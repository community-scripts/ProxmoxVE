#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: ksad (enirys31)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://garethgeorge.github.io/backrest/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "backrest" "garethgeorge/backrest" "prebuild" "latest" "/opt/backrest/bin" "backrest_Linux_x86_64.tar.gz"

msg_info "Creating Service"
cat <<EOF >/opt/backrest/.env
BACKREST_PORT=9898
BACKREST_CONFIG=/opt/backrest/config/config.json
BACKREST_DATA=/opt/backrest/data
XDG_CACHE_HOME=/opt/backrest/cache
EOF

cat <<EOF >/etc/systemd/system/backrest.service
[Unit]
Description=Backrest
After=network.target

[Service]
Type=simple
ExecStart=/opt/backrest/bin/backrest
EnvironmentFile=/opt/backrest/.env

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now backrest
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
