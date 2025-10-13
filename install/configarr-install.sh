#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: finkerle
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/raydak-labs/configarr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y git
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "configarr" "raydak-labs/configarr" "prebuild" "latest" "/opt/configarr" "configarr-linux-x64.tar.xz"

msg_info "Setup Configarr"
cat <<EOF >/opt/configarr/.env
ROOT_PATH=/opt/configarr
CUSTOM_REPO_ROOT=/opt/configarr/repos
CONFIG_LOCATION=/opt/configarr/config.yml
SECRETS_LOCATION=/opt/configarr/secrets.yml
EOF

cd /opt/configarr
curl -fsSLO https://raw.githubusercontent.com/raydak-labs/configarr/refs/heads/main/examples/full/config/config.yml
curl -fsSLO https://raw.githubusercontent.com/raydak-labs/configarr/refs/heads/main/examples/full/config/secrets.yml
sed 's|#localConfigTemplatesPath: /app/templates|#localConfigTemplatesPath: /opt/configarr/templates|' /opt/configarr/config.yml
msg_ok "Setup Configarr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/configarr-task.service
[Unit]
Description=Run Configarr Task

[Service]
Type=simple
WorkingDirectory=/opt/configarr
ExecStart=/opt/configarr/configarr
EOF

cat <<EOF >/etc/systemd/system/configarr-task.timer
[Unit]
Description=Run Configarr every 5 minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl enable -q --now configarr-task.timer configarr-task.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
