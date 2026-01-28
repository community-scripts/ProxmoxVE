#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.meilisearch.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

MEILISEARCH_BIND="0.0.0.0:7700" setup_meilisearch

read -r -p "${TAB3}Do you want add meilisearch-ui? [y/n]: " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  NODE_VERSION="22" NODE_MODULE="pnpm@latest" setup_nodejs
  fetch_and_deploy_gh_release "meilisearch-ui" "riccox/meilisearch-ui" "tarball"

  msg_info "Configuring ${APPLICATION}-ui"
  cd /opt/meilisearch-ui
  sed -i 's|const hash = execSync("git rev-parse HEAD").toString().trim();|const hash = "unknown";|' /opt/meilisearch-ui/vite.config.ts
  $STD pnpm install
  cat <<EOF >/opt/meilisearch-ui/.env.local
VITE_SINGLETON_MODE=true
VITE_SINGLETON_HOST=http://${LOCAL_IP}:7700
VITE_SINGLETON_API_KEY=${MEILISEARCH_MASTER_KEY}
EOF
  msg_ok "Configured ${APPLICATION}-ui"

  msg_info "Creating Meilisearch-UI service"
  cat <<EOF >/etc/systemd/system/meilisearch-ui.service
[Unit]
Description=Meilisearch UI Service
After=network.target meilisearch.service
Requires=meilisearch.service

[Service]
User=root
WorkingDirectory=/opt/meilisearch-ui
ExecStart=/usr/bin/pnpm start
Restart=always
RestartSec=5
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=meilisearch-ui

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now meilisearch-ui
  msg_ok "Created Meilisearch-UI service"
fi

motd_ssh
customize
cleanup_lxc
