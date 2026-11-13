#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/arp242/goatcounter

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "goatcounter" "arp242/goatcounter" "singlefile" "latest" "/opt/goatcounter" "goatcounter-v*-linux-$(arch_resolve).gz"
mv /opt/goatcounter/goatcounter /opt/goatcounter/goatcounter.gz
gunzip -f /opt/goatcounter/goatcounter.gz

msg_info "Configuring GoatCounter"
ADMIN_EMAIL="${var_admin_email:-admin@goatcounter.local}"
ADMIN_PASS="${var_admin_pass:-$(random_password)}"
mkdir -p /opt/goatcounter_data
cat <<EOF >/opt/goatcounter_data/.env
GOATCOUNTER_DB=sqlite+/opt/goatcounter_data/db.sqlite3
GOATCOUNTER_LISTEN=:8080
GOATCOUNTER_TLS=http
ADMIN_EMAIL=${ADMIN_EMAIL}
ADMIN_PASSWORD=${ADMIN_PASS}
EOF
chmod 600 /opt/goatcounter_data/.env
$STD /opt/goatcounter/goatcounter db create site -createdb \
  -db sqlite+/opt/goatcounter_data/db.sqlite3 \
  -vhost "${var_goatcounter_domain:-$LOCAL_IP}" \
  -user.email "$ADMIN_EMAIL" \
  -user.password "$ADMIN_PASS"
msg_ok "Configured GoatCounter"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/goatcounter.service
[Unit]
Description=GoatCounter
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/goatcounter_data
EnvironmentFile=/opt/goatcounter_data/.env
ExecStart=/opt/goatcounter/goatcounter serve -automigrate
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now goatcounter
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
