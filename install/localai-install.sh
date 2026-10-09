#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Bryan Lieberman (BryanCLieberman)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://localai.io

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  libgomp1 \
  libopenblas0
msg_ok "Installed Dependencies"

setup_hwaccel
var_port="${var_port:-8080}"
var_auth="${var_auth:-no}"
var_api_key="${var_api_key:-}"
if [[ "$var_auth" == "yes" ]]; then
  setup_postgresql
  PG_DB_NAME="localai" PG_DB_USER="localai" setup_postgresql_db
fi

fetch_and_deploy_gh_release "localai" "mudler/LocalAI" "singlefile" "latest" "/opt/localai" "local-ai-v*-linux-$(arch_resolve amd64 arm64)"

msg_info "Configuring LocalAI"
mkdir -p /opt/localai_data/models /opt/localai_data/backends
cat <<EOF >/opt/localai.env
LOCALAI_ADDRESS=0.0.0.0:${var_port}
LOCALAI_DATA_PATH=/opt/localai_data
LOCALAI_MODELS_PATH=/opt/localai_data/models
LOCALAI_BACKENDS_PATH=/opt/localai_data/backends
LOCALAI_LOG_LEVEL=info
EOF
# LocalAI refuses to start on a wildcard bind with nothing to identify callers,
# and binding the wildcard is what makes the container reachable at all.
if [[ "$var_auth" == "yes" ]]; then
  cat <<EOF >>/opt/localai.env
LOCALAI_AUTH=true
LOCALAI_AUTH_DATABASE_URL=postgres://${PG_DB_USER}:${PG_DB_PASS}@localhost/${PG_DB_NAME}
LOCALAI_REGISTRATION_MODE=approval
EOF
fi
# A static key grants admin access on its own, so when it is the only thing
# guarding the API, generate one rather than leaving the server open.
if [[ -z "$var_api_key" && "$var_auth" != "yes" ]]; then
  var_api_key="sk-$(openssl rand -hex 24)"
  {
    echo "LocalAI Credentials"
    echo "API Key: ${var_api_key}"
  } >>~/localai.creds
fi
if [[ -n "$var_api_key" ]]; then
  echo "LOCALAI_API_KEY=${var_api_key}" >>/opt/localai.env
else
  echo "#LOCALAI_API_KEY=" >>/opt/localai.env
fi
chmod 600 /opt/localai.env
msg_ok "Configured LocalAI"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/localai.service
[Unit]
Description=LocalAI Server
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/localai
EnvironmentFile=/opt/localai.env
ExecStart=/opt/localai/localai run
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now localai
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
