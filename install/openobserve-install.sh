#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
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
$STD apt-get install -y sudo
$STD apt-get install -y mc
msg_ok "Installed Dependencies"

msg_info "Installing OpenObserve"
mkdir -p /opt/openobserve/data
LATEST=$(curl -sL https://api.github.com/repos/openobserve/openobserve/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
$STD tar zxvf <(curl -fsSL https://github.com/openobserve/openobserve/releases/download/$LATEST/openobserve-${LATEST}-linux-amd64.tar.gz) -C /opt/openobserve

cat <<EOF >/opt/openobserve/data/.env
ZO_ROOT_USER_EMAIL = "admin@example.com"
ZO_ROOT_USER_PASSWORD = "$(openssl rand -base64 18 | cut -c1-13)"
ZO_DATA_DIR = "/opt/openobserve/data"
ZO_HTTP_PORT = "5080"
EOF
msg_ok "Installed OpenObserve"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/openobserve.service
[Unit]
Description=OpenObserve
After=network.target

[Service]
Type=simple
EnvironmentFile=/opt/openobserve/data/.env
ExecStart=/opt/openobserve/openobserve
ExecStop=killall -QUIT openobserve
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now openobserve
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
