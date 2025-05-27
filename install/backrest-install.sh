#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
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

msg_info "Installing Backrest"
RELEASE=$(curl -fsSL https://api.github.com/repos/garethgeorge/backrest/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
temp_file=$(mktemp)
mkdir -p /opt/backrest/{bin,config,data}
curl -fsSL "https://github.com/garethgeorge/backrest/releases/download/v${RELEASE}/backrest_Linux_x86_64.tar.gz" -o "$temp_file"
tar xzf $temp_file -C /opt/backrest/bin
chmod +x /opt/backrest/bin/backrest
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed Backrest"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/backrest.service
[Unit]
Description=Backrest
After=network.target

[Service]
Type=simple
User=root
ExecStart=/opt/backrest/bin/backrest
Environment="BACKREST_PORT=9898"
Environment="BACKREST_CONFIG=/opt/backrest/config/config.json"
Environment="BACKREST_DATA=/opt/backrest/data"
Environment="XDG_CACHE_HOME=/opt/backrest/cache"

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now backrest
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f "$temp_file"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
