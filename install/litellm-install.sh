#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
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

PG_VERSION="17" setup_postgresql
PYTHON_VERSION="3.13" setup_uv

msg_info "Setting up PostgreSQL"
DB_NAME="litellm_db"
DB_USER="litellm"
DB_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC';"
{
  echo "${APPLICATION} Credentials"
  echo "Database Name: $DB_NAME"
  echo "Database User: $DB_USER"
  echo "Database Password: $DB_PASS"
} >>~/litellm.creds
msg_ok "Set up PostgreSQL"

msg_info "Setting up Virtual Environment"
mkdir -p /opt/litellm
cd /opt/litellm
$STD uv venv /opt/litellm/.venv
$STD /opt/litellm/.venv/bin/python -m ensurepip --upgrade
$STD /opt/litellm/.venv/bin/python -m pip install --upgrade pip
$STD /opt/litellm/.venv/bin/python -m pip install litellm[proxy] prisma
msg_ok "Installed LiteLLM"

msg_info "Configuring LiteLLM"
mkdir -p /opt
cat <<EOF >/opt/litellm/litellm.yaml
general_settings:
  master_key: sk-1234
  database_url: postgresql://$DB_USER:$DB_PASS@127.0.0.1:5432/$DB_NAME
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

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
