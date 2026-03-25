#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: stout01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/BerriAI/litellm

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  python3-dev
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
PG_DB_NAME="litellm_db" PG_DB_USER="litellm" setup_postgresql_db
PYTHON_VERSION="3.13" USE_UVX="YES" setup_uv

msg_info "Setting up Virtual Environment"
mkdir -p /opt/litellm
cd /opt/litellm
$STD uv venv --clear /opt/litellm/.venv
$STD /opt/litellm/.venv/bin/python -m ensurepip --upgrade
$STD /opt/litellm/.venv/bin/python -m pip install --upgrade pip
$STD /opt/litellm/.venv/bin/python -m pip install litellm[proxy] prisma
msg_ok "Installed LiteLLM"

msg_info "Configuring LiteLLM"
mkdir -p /opt
cat <<EOF >/opt/litellm/litellm.yaml
general_settings:
  master_key: sk-1234
  database_url: postgresql://$PG_DB_USER:$PG_DB_PASS@127.0.0.1:5432/$PG_DB_NAME
  store_model_in_db: true
EOF
uv --directory=/opt/litellm run litellm --config /opt/litellm/litellm.yaml --use_prisma_db_push --skip_server_startup
msg_ok "Configured LiteLLM"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/litellm.service
[Unit]
Description=LiteLLM

[Service]
Type=simple
ExecStart=uv --directory=/opt/litellm run litellm --config /opt/litellm/litellm.yaml
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now litellm
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
