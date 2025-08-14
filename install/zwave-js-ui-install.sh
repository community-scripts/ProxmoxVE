#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://zwave-js.github.io/zwave-js-ui/#/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "zwave-js-ui" "zwave-js/zwave-js-ui" "prebuild" "latest" "/opt/zwave-js-ui" "zwave-js-ui*-linux.zip"

msg_info "Configuring Z-Wave JS UI"
mkdir -p /opt/zwave_store
cat <<EOF >/opt/.env
ZWAVEJS_EXTERNAL_CONFIG=/opt/zwave_store/.config-db
STORE_DIR=/opt/zwave_store
EOF
msg_ok "Configured Z-Wave JS UI"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/zwave-js-ui.service
[Unit]
Description=zwave-js-ui
Wants=network-online.target
After=network-online.target

[Service]
User=root
WorkingDirectory=/opt/zwave-js-ui
ExecStart=/opt/zwave-js-ui/zwave-js-ui-linux
EnvironmentFile=/opt/.env

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now zwave-js-ui
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
