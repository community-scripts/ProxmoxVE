#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://cassandra.apache.org/_/index.html

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

JAVA_VERSION="11" setup_java

msg_info "Installing Apache Cassandra"
setup_deb822_repo \
  "cassandra" \
  "https://downloads.apache.org/cassandra/KEYS" \
  "https://debian.cassandra.apache.org" \
  "41x" \
  "main"
$STD apt install -y cassandra cassandra-tools
sed -i -e 's/^rpc_address: localhost/#rpc_address: localhost/g' -e 's/^# rpc_interface: eth1/rpc_interface: eth0/g' /etc/cassandra/cassandra.yaml
msg_ok "Installed Apache Cassandra"

motd_ssh
customize
cleanup_lxc
