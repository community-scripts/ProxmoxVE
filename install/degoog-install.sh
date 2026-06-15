#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/fccview/degoog

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  git \
  unzip \
  valkey
msg_ok "Installed Dependencies"

msg_info "Installing Bun"
export BUN_INSTALL="/root/.bun"
curl -fsSL https://bun.sh/install | $STD bash
ln -sf /root/.bun/bin/bun /usr/local/bin/bun
ln -sf /root/.bun/bin/bunx /usr/local/bin/bunx
msg_ok "Installed Bun"

fetch_and_deploy_gh_release "curl-impersonate" "lexiforest/curl-impersonate" "prebuild" "latest" "/usr/local/bin" "curl-impersonate-v*.$(uname -m)-linux-gnu.tar.gz"
fetch_and_deploy_gh_release "degoog" "fccview/degoog" "prebuild" "latest" "/opt/degoog" "degoog_*_prebuild.tar.gz"

msg_info "Setting up degoog"
mkdir -p /opt/degoog/data/{engines,plugins,themes,store}

cat <<EOF >/opt/degoog/.env
DEGOOG_PORT=4444
DEGOOG_ENGINES_DIR=/opt/degoog/data/engines
DEGOOG_PLUGINS_DIR=/opt/degoog/data/plugins
DEGOOG_THEMES_DIR=/opt/degoog/data/themes
DEGOOG_ALIASES_FILE=/opt/degoog/data/aliases.json
DEGOOG_PLUGIN_SETTINGS_FILE=/opt/degoog/data/plugin-settings.json
DEGOOG_VALKEY_URL=redis://valkey:6379
DEGOOG_CACHE_MAX_ENTRIES=1000
DEGOOG_CACHE_TTL_MS=43200000
# DEGOOG_SETTINGS_PASSWORDS=changeme
# DEGOOG_PUBLIC_INSTANCE=false
# LOGGER=debug
EOF

if [[ ! -f /opt/degoog/data/aliases.json ]]; then
  cat <<EOF >/opt/degoog/data/aliases.json
{}
EOF
fi

if [[ ! -f /opt/degoog/data/plugin-settings.json ]]; then
  cat <<EOF >/opt/degoog/data/plugin-settings.json
{}
EOF
fi

if [[ ! -f /opt/degoog/data/repos.json ]]; then
  cat <<EOF >/opt/degoog/data/repos.json
[]
EOF
fi
msg_ok "Set up degoog"

msg_info "Starting Valkey Service"
systemctl enable -q --now valkey-server
msg_ok "Started Valkey Service"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/degoog.service
[Unit]
Description=degoog
After=network.target valkey-server.service
Wants=valkey-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/degoog
EnvironmentFile=/opt/degoog/.env
ExecStart=/usr/local/bin/bun run src/server/index.ts
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now degoog
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
