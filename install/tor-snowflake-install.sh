#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: KernelSailor
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
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
RELEASE=$(curl -fsSL https://gitlab.torproject.org/api/v4/projects/tpo%2Fanti-censorship%2Fpluggable-transports%2Fsnowflake/releases | jq -r '.[0].tag_name' | sed 's/^v//')
$STD curl -fsSL "https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/snowflake/-/archive/v${RELEASE}/snowflake-v${RELEASE}.tar.gz" -o /opt/snowflake.tar.gz
$STD tar -xzf /opt/snowflake.tar.gz -C /opt
rm -rf /opt/snowflake.tar.gz
mv /opt/snowflake-v${RELEASE} /opt/tor-snowflake
cd /opt/tor-snowflake/proxy
$STD go build -o snowflake-proxy .
echo "${RELEASE}" >~/.tor-snowflake
msg_ok "Built Snowflake Proxy v${RELEASE}"

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
