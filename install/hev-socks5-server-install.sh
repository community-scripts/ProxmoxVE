#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: miviro
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/heiher/hev-socks5-server

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "hev-socks5-server" "heiher/hev-socks5-server" "singlefile" "latest" "/opt" "hev-socks5-server-linux-x86_64"

msg_info "Setup hev-socks5-server"
mkdir -p /etc/hev-socks5-server
download_file "https://raw.githubusercontent.com/heiher/hev-socks5-server/refs/heads/main/conf/main.yml" "/etc/hev-socks5-server/main.yml"
sed -i 's/^#auth:/auth:/; s/^# file: conf\/auth.txt/  file: \/root\/hev.creds/'  /etc/hev-socks5-server/main.yml
PASSWORD=$(openssl rand -base64 16)
echo "admin $PASSWORD 0" >/root/hev.creds
msg_ok "Setup hev-socks5-server"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/hev-socks5-server.service
[Unit]
Description=hev-socks5-server Service
After=network.target

[Service]
ExecStart=/opt/hev-socks5-server /etc/hev-socks5-server/main.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now hev-socks5-server
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
