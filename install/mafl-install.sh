#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://mafl.hywax.space/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y make
$STD apt-get install -y g++
$STD apt-get install -y gcc
$STD apt-get install -y ca-certificates
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="yarn@latest" setup_nodejs

RELEASE=$(curl -fsSL https://api.github.com/repos/hywax/mafl/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
msg_info "Installing Mafl v${RELEASE}"
curl -fsSL "https://github.com/hywax/mafl/archive/refs/tags/v${RELEASE}.tar.gz" -o "v${RELEASE}.tar.gz"
tar -xzf v${RELEASE}.tar.gz
mkdir -p /opt/mafl/data
curl -fsSL "https://raw.githubusercontent.com/hywax/mafl/main/.example/config.yml" -o "/opt/mafl/data/config.yml"
mv mafl-${RELEASE}/* /opt/mafl
rm -rf mafl-${RELEASE}
cd /opt/mafl
export NUXT_TELEMETRY_DISABLED=true
$STD yarn install
$STD yarn build
msg_ok "Installed Mafl v${RELEASE}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/mafl.service
[Unit]
Description=Mafl
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
WorkingDirectory=/opt/mafl/
ExecStart=yarn preview

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now mafl
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
