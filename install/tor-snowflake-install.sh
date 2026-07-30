#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: KernelSailor
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://snowflake.torproject.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_go

msg_info "Building Snowflake"
GITLAB_URL="https://gitlab.torproject.org" fetch_and_deploy_gl_release "tor-snowflake" "tpo/anti-censorship/pluggable-transports/snowflake" "tarball"
cd /opt/tor-snowflake/proxy
$STD go build -o snowflake-proxy .
msg_ok "Built Snowflake Proxy"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/snowflake-proxy.service
[Unit]
Description=Snowflake Proxy Service
Documentation=https://snowflake.torproject.org/
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/tor-snowflake/proxy
ExecStart=/opt/tor-snowflake/proxy/snowflake-proxy -verbose -unsafe-logging
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now snowflake-proxy
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
