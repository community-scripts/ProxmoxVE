#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/apache/airflow

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
  libpq-dev \
  libssl-dev \
  libffi-dev \
  python3-dev
msg_ok "Installed Dependencies"

UV_PYTHON="3.12" setup_uv
PG_VERSION="16" setup_postgresql
PG_DB_NAME="airflow" PG_DB_USER="airflow" setup_postgresql_db

msg_info "Installing Apache Airflow"
AIRFLOW_VERSION="3.2.1"
mkdir -p /opt/airflow/{dags,logs,plugins}
cd /opt/airflow
$STD uv venv --python 3.12
$STD uv pip install --python /opt/airflow/.venv/bin/python \
  "apache-airflow[postgres,fab]==${AIRFLOW_VERSION}" \
  --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-3.12.txt"
echo "${AIRFLOW_VERSION}" >~/.airflow
msg_ok "Installed Apache Airflow"

msg_info "Configuring Application"
FERNET_KEY=$(/opt/airflow/.venv/bin/python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
SECRET_KEY=$(openssl rand -hex 32)
ADMIN_PASS=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | cut -c1-12)
cat <<EOF >/opt/airflow/.env
AIRFLOW_HOME=/opt/airflow
AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql+psycopg2://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}
AIRFLOW__CORE__EXECUTOR=LocalExecutor
AIRFLOW__CORE__FERNET_KEY=${FERNET_KEY}
AIRFLOW__CORE__DAGS_FOLDER=/opt/airflow/dags
AIRFLOW__CORE__LOAD_EXAMPLES=false
AIRFLOW__CORE__AUTH_MANAGER=airflow.providers.fab.auth_manager.fab_auth_manager.FabAuthManager
AIRFLOW__API__AUTH_BACKENDS=airflow.api.auth.backend.basic_auth,airflow.api.auth.backend.session
AIRFLOW__WEBSERVER__SECRET_KEY=${SECRET_KEY}
AIRFLOW__WEBSERVER__BASE_URL=http://${LOCAL_IP}:8080
AIRFLOW_ADMIN_PASSWORD=${ADMIN_PASS}
EOF
set -a && source /opt/airflow/.env && set +a
$STD /opt/airflow/.venv/bin/airflow db migrate
$STD /opt/airflow/.venv/bin/airflow users create \
  --username admin \
  --firstname Admin \
  --lastname User \
  --role Admin \
  --email admin@example.com \
  --password "${ADMIN_PASS}"
msg_ok "Configured Application"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/airflow-api-server.service
[Unit]
Description=Apache Airflow API Server
After=network.target postgresql.service

[Service]
Type=simple
User=root
EnvironmentFile=/opt/airflow/.env
ExecStart=/opt/airflow/.venv/bin/airflow api-server --port 8080
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/airflow-scheduler.service
[Unit]
Description=Apache Airflow Scheduler
After=network.target postgresql.service

[Service]
Type=simple
User=root
EnvironmentFile=/opt/airflow/.env
ExecStart=/opt/airflow/.venv/bin/airflow scheduler
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/airflow-dag-processor.service
[Unit]
Description=Apache Airflow DAG Processor
After=network.target postgresql.service

[Service]
Type=simple
User=root
EnvironmentFile=/opt/airflow/.env
ExecStart=/opt/airflow/.venv/bin/airflow dag-processor
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/airflow-triggerer.service
[Unit]
Description=Apache Airflow Triggerer
After=network.target postgresql.service

[Service]
Type=simple
User=root
EnvironmentFile=/opt/airflow/.env
ExecStart=/opt/airflow/.venv/bin/airflow triggerer
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now airflow-api-server airflow-scheduler airflow-dag-processor airflow-triggerer
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
