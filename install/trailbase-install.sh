#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/trailbaseio/trailbase

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "trailbase" "trailbaseio/trailbase" "prebuild" "latest" "/opt/trailbase" "trailbase_v*_$(arch_resolve "x86_64" "aarch64")_linux.zip"

msg_info "Configuring TrailBase"
ADMIN_EMAIL="${var_admin_email:-admin@localhost}"
ADMIN_PASS="${var_admin_pass:-$(random_password)}"
mkdir -p /opt/trailbase_data
cat <<EOF >/opt/trailbase_data/.env
DEPOT=/opt/trailbase_data/traildepot
ADDRESS=0.0.0.0:4000
PUBLIC_URL=http://${LOCAL_IP}:4000
TRAILBASE_ADMIN_EMAIL=${ADMIN_EMAIL}
TRAILBASE_ADMIN_PASSWORD=${ADMIN_PASS}
EOF
chmod 600 /opt/trailbase_data/.env
# The first CLI call creates the depot and the admin user admin@localhost
$STD /opt/trailbase/trail --depot /opt/trailbase_data/traildepot user change-password admin@localhost "$ADMIN_PASS"
if [[ "$ADMIN_EMAIL" != "admin@localhost" ]]; then
  $STD /opt/trailbase/trail --depot /opt/trailbase_data/traildepot user change-email admin@localhost "$ADMIN_EMAIL"
fi
msg_ok "Configured TrailBase"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/trailbase.service
[Unit]
Description=TrailBase
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/trailbase_data
EnvironmentFile=/opt/trailbase_data/.env
ExecStart=/opt/trailbase/trail run
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now trailbase
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
