#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/langflow-ai/langflow

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="24" setup_nodejs
PYTHON_VERSION="3.14" USE_UVX="YES" setup_uv

LANGFLOW_VERSION="${var_appversion:-$(get_latest_github_release "langflow-ai/langflow")}"
msg_info "Installing Langflow ${LANGFLOW_VERSION#v}"
$STD uv venv --python 3.14 /opt/langflow/.venv
$STD uv pip install --python /opt/langflow/.venv/bin/python "langflow==${LANGFLOW_VERSION#v}"
cat <<EOF >~/.langflow
${LANGFLOW_VERSION#v}
EOF
msg_ok "Installed Langflow ${LANGFLOW_VERSION#v}"

msg_info "Configuring Langflow"
mkdir -p /opt/langflow_data/logs
cat <<EOF >/opt/langflow_data/.env
LANGFLOW_HOST=0.0.0.0
LANGFLOW_PORT=7860
LANGFLOW_CONFIG_DIR=/opt/langflow_data
LANGFLOW_DATABASE_URL=sqlite:////opt/langflow_data/langflow.db
LANGFLOW_KNOWLEDGE_BASES_DIR=/opt/langflow_data/knowledge_bases
LANGFLOW_LOG_FILE=/opt/langflow_data/logs/langflow.log
LANGFLOW_SECRET_KEY=$(/opt/langflow/.venv/bin/python -c "from secrets import token_urlsafe; print(token_urlsafe(32))")
LANGFLOW_AUTO_LOGIN=False
LANGFLOW_SUPERUSER='${var_admin_user:-langflow}'
LANGFLOW_SUPERUSER_PASSWORD='${var_admin_pass:-$(random_password)}'
EOF
chmod 600 /opt/langflow_data/.env
msg_ok "Configured Langflow"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/langflow.service
[Unit]
Description=Langflow
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/langflow_data
EnvironmentFile=/opt/langflow_data/.env
ExecStart=/opt/langflow/.venv/bin/langflow run
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now langflow
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
