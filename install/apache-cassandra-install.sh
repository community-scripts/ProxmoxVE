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
$STD apt-get install -y apt-transport-https
$STD apt-get install -y gpg
msg_ok "Installed Dependencies"

msg_info "Installing Eclipse Temurin (Patience)"
wget -qO- https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor >/etc/apt/trusted.gpg.d/adoptium.gpg
echo 'deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/adoptium.gpg] https://packages.adoptium.net/artifactory/deb bookworm main' >/etc/apt/sources.list.d/adoptium.list
$STD apt-get update
$STD apt-get install -y temurin-11-jdk
msg_ok "Installed Eclipse Temurin"

msg_info "Installing Apache Cassandra"
wget -qO- https://downloads.apache.org/cassandra/KEYS | gpg --dearmor >/etc/apt/trusted.gpg.d/cassandra.gpg
echo "deb https://debian.cassandra.apache.org 41x main" >/etc/apt/sources.list.d/cassandra.sources.list
$STD apt-get update
$STD apt-get install -y cassandra cassandra-tools
sed -i -e 's/^rpc_address: localhost/#rpc_address: localhost/g' -e 's/^# rpc_interface: eth1/rpc_interface: eth0/g' /etc/cassandra/cassandra.yaml
msg_ok "Installed Apache Cassandra"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
