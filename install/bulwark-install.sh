#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bulwarkmail/webmail

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="24" setup_nodejs

fetch_and_deploy_gh_release "bulwark" "bulwarkmail/webmail" "prebuild" "latest" "/opt/bulwark" "bulwark-standalone-*-linux-$(arch_resolve).tar.gz"

msg_info "Configuring Bulwark"
mkdir -p /opt/bulwark_data
cat <<EOF >/opt/bulwark_data/.env
NODE_ENV=production
HOSTNAME=0.0.0.0
PORT=3000
JMAP_SERVER_URL=${var_jmap_url:-}
COOKIE_SECURE=false
ADMIN_CONFIG_DIR=/opt/bulwark_data/admin
ADMIN_STATE_DIR=/opt/bulwark_data/admin-state
SETTINGS_DATA_DIR=/opt/bulwark_data/settings
PLUGIN_SECRETS_DIR=/opt/bulwark_data/plugin-secrets
TELEMETRY_DATA_DIR=/opt/bulwark_data/telemetry
VERSION_CHECK_DATA_DIR=/opt/bulwark_data/version-check
EOF
chmod 600 /opt/bulwark_data/.env
msg_ok "Configured Bulwark"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/bulwark.service
[Unit]
Description=Bulwark Webmail
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/bulwark
EnvironmentFile=/opt/bulwark_data/.env
ExecStart=/usr/bin/node /opt/bulwark/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now bulwark
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
