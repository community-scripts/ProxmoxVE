#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Ali M. Jaradat (amjaradat01)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://clickhouse.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y apt-transport-https
msg_ok "Installed Dependencies"

msg_info "Setting up ClickHouse Repository"
ARCH=$(dpkg --print-architecture)
curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' | gpg --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg arch=${ARCH}] https://packages.clickhouse.com/deb stable main" >/etc/apt/sources.list.d/clickhouse.list
$STD apt-get update
msg_ok "Set up ClickHouse Repository"

msg_info "Installing ClickHouse"
$STD DEBIAN_FRONTEND=noninteractive apt-get install -y clickhouse-server clickhouse-client
msg_ok "Installed ClickHouse"

msg_info "Configuring ClickHouse"
cat <<EOF >/etc/security/limits.d/clickhouse.conf
clickhouse      soft    nofile  262144
clickhouse      hard    nofile  262144
EOF

mkdir -p /etc/clickhouse-server/config.d
cat <<EOF >/etc/clickhouse-server/config.d/listen.xml
<clickhouse>
    <listen_host>0.0.0.0</listen_host>
</clickhouse>
EOF
msg_ok "Configured ClickHouse"

msg_info "Starting ClickHouse"
systemctl enable -q --now clickhouse-server
msg_ok "Started ClickHouse"

motd_ssh
customize
cleanup_lxc
