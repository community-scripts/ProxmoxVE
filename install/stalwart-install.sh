#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/stalwartlabs/stalwart

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "stalwart" "stalwartlabs/stalwart" "prebuild" "latest" "/opt/stalwart" "stalwart-$(arch_resolve x86_64 aarch64)-unknown-linux-gnu.tar.gz"
chmod +x /opt/stalwart/stalwart

msg_info "Configuring Stalwart"
mkdir -p /opt/stalwart_data/{etc,data,logs}
cat <<EOF >/opt/stalwart_data/etc/stalwart.env
# Uncomment and edit an entry to override its default.
# Apply changes with: systemctl restart stalwart

#STALWART_HOSTNAME=mail.example.com
#STALWART_PUBLIC_URL=https://mail.example.com
#STALWART_RECOVERY_MODE=true
#STALWART_RECOVERY_ADMIN=admin:changeme
EOF
chmod 600 /opt/stalwart_data/etc/stalwart.env
msg_ok "Configured Stalwart"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/stalwart.service
[Unit]
Description=Stalwart Mail Server
Conflicts=postfix.service sendmail.service exim4.service
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/stalwart_data
EnvironmentFile=-/opt/stalwart_data/etc/stalwart.env
ExecStart=/opt/stalwart/stalwart --config=/opt/stalwart_data/etc/config.json
LimitNOFILE=65536
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
SyslogIdentifier=stalwart

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now stalwart
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
