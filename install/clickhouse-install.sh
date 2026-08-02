#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://clickhouse.com

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_clickhouse

msg_info "Configuring ClickHouse"
cat <<EOF >/etc/clickhouse-server/config.d/listen.xml
<clickhouse>
    <listen_host>0.0.0.0</listen_host>
</clickhouse>
EOF
systemctl restart clickhouse-server
msg_ok "Configured ClickHouse"

motd_ssh
customize
cleanup_lxc
