#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://openobserve.ai/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing OpenObserve"
mkdir -p /opt/openobserve/data
RELEASE=$(get_latest_github_release "openobserve/openobserve")
tar zxf <(curl -fsSL https://downloads.openobserve.ai/releases/openobserve/v$RELEASE/openobserve-v$RELEASE-linux-amd64.tar.gz) -C /opt/openobserve
ROOT_PASS=$(openssl rand -base64 18 | cut -c1-13)

cat <<EOF >/opt/openobserve/data/.env
ZO_ROOT_USER_EMAIL = "admin@example.com"
ZO_ROOT_USER_PASSWORD = "${ROOT_PASS}"
ZO_DATA_DIR = "/opt/openobserve/data"
ZO_HTTP_PORT = "5080"
EOF
echo "${RELEASE}" >>~/.openobserve
msg_ok "Installed OpenObserve"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/openobserve.service
[Unit]
Description=OpenObserve
After=network.target

[Service]
Type=simple
EnvironmentFile=/opt/openobserve/data/.env
ExecStart=/opt/openobserve/openobserve
ExecStop=killall -QUIT openobserve
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now openobserve
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
