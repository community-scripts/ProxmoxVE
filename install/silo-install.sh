#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pgsty/silo

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "silo" "pgsty/silo" "binary"

msg_info "Configuring Silo"
mkdir -p /opt/silo_data
chown silo:silo /opt/silo_data
SILO_ROOT_PASSWORD=$(random_password 32)
cat <<EOF >/etc/default/silo
MINIO_VOLUMES="/opt/silo_data"
MINIO_OPTS="--console-address :9001"
MINIO_ROOT_USER="silo-admin"
MINIO_ROOT_PASSWORD="${SILO_ROOT_PASSWORD}"
EOF
chmod 600 /etc/default/silo
msg_ok "Configured Silo"

msg_info "Starting Silo"
systemctl enable -q --now silo
msg_ok "Started Silo"

motd_ssh
customize
cleanup_lxc
