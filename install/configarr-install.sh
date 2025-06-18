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
$STD apt-get install -y \
  git
msg_ok "Installed Dependencies"

NODE_MODULE="pnpm@latest" setup_nodejs
fetch_and_deploy_gh_release "configarr" "raydak-labs/configarr"

msg_info "Setup ${APPLICATION}"
cat <<EOF >/opt/configarr/.env
ROOT_PATH=/opt/configarr
CUSTOM_REPO_ROOT=/opt/configarr/repos
CONFIG_LOCATION=/opt/configarr/config.yml
SECRETS_LOCATION=/opt/configarr/secrets.yml
EOF
mv /opt/configarr/secrets.yml.template /opt/configarr/secrets.yml
sed 's|#localConfigTemplatesPath: /app/templates|#localConfigTemplatesPath: /opt/configarr/templates|' /opt/configarr/config.yml.template >/opt/configarr/config.yml
cd /opt/configarr
$STD pnpm install
$STD pnpm run build
msg_ok "Setup ${APPLICATION}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/configarr-task.service
[Unit]
Description=Run Configarr Task

[Service]
Type=oneshot
WorkingDirectory=/opt/configarr
ExecStart=/usr/bin/node /opt/configarr/bundle.cjs
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
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
