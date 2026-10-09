#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://mailpit.axllent.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "mailpit" "axllent/mailpit" "prebuild" "latest" "/opt/mailpit" "mailpit-linux-$(arch_resolve).tar.gz"

msg_info "Configuring Mailpit"
mkdir -p /opt/mailpit/data
cat <<EOF >/opt/mailpit/.env
MP_DATABASE=/opt/mailpit/data/mailpit.db
MP_UI_BIND_ADDR=0.0.0.0:8025
MP_SMTP_BIND_ADDR=0.0.0.0:1025
MP_DISABLE_VERSION_CHECK=true
EOF
msg_ok "Configured Mailpit"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/mailpit.service
[Unit]
Description=Mailpit Email Testing Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/mailpit
EnvironmentFile=/opt/mailpit/.env
ExecStart=/opt/mailpit/mailpit
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now mailpit
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
