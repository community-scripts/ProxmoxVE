#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Yamon
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.langflow.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
if ! install_packages_with_retry \
  build-essential \
  python3-dev \
  curl \
  git; then
  msg_error "Failed to install dependencies"
  exit 1
fi
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.12" setup_uv
LANGFLOW_VERSION="${LANGFLOW_VERSION:-1.7.3}"
APPLICATION="Langflow"
UV_CONCURRENT_DOWNLOADS="${UV_CONCURRENT_DOWNLOADS:-2}"
UV_CONCURRENT_BUILDS="${UV_CONCURRENT_BUILDS:-1}"
UV_CONCURRENT_INSTALLS="${UV_CONCURRENT_INSTALLS:-1}"
LANGFLOW_NO_CACHE="${LANGFLOW_NO_CACHE:-false}"
UV_CACHE_ARGS=()
if [[ "${LANGFLOW_NO_CACHE,,}" == "true" || "${LANGFLOW_NO_CACHE}" == "1" ]]; then
  UV_CACHE_ARGS+=(--no-cache)
fi

msg_info "Installing Langflow"
mkdir -p /opt/langflow/data
cd /opt/langflow
$STD uv venv --clear /opt/langflow/.venv
$STD /opt/langflow/.venv/bin/python -m ensurepip --upgrade
$STD /opt/langflow/.venv/bin/python -m pip install --upgrade pip
PYTHON_VENV_VERSION="$("/opt/langflow/.venv/bin/python" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
verify_tool_version "python" "3.12" "${PYTHON_VENV_VERSION}" || true
$STD env \
  UV_CONCURRENT_DOWNLOADS="${UV_CONCURRENT_DOWNLOADS}" \
  UV_CONCURRENT_BUILDS="${UV_CONCURRENT_BUILDS}" \
  UV_CONCURRENT_INSTALLS="${UV_CONCURRENT_INSTALLS}" \
  uv pip install --python /opt/langflow/.venv/bin/python "${UV_CACHE_ARGS[@]}" \
  --index-strategy unsafe-best-match \
  --index-url https://download.pytorch.org/whl/cpu \
  --extra-index-url https://pypi.org/simple \
  "torch==2.8.0+cpu"
$STD env \
  UV_CONCURRENT_DOWNLOADS="${UV_CONCURRENT_DOWNLOADS}" \
  UV_CONCURRENT_BUILDS="${UV_CONCURRENT_BUILDS}" \
  UV_CONCURRENT_INSTALLS="${UV_CONCURRENT_INSTALLS}" \
  uv pip install --python /opt/langflow/.venv/bin/python "${UV_CACHE_ARGS[@]}" "langflow==${LANGFLOW_VERSION}"
msg_ok "Installed Langflow"

msg_info "Configuring Langflow"
get_lxc_ip
LOCAL_IP="${LOCAL_IP:-$IP}"
APP_NAME="Langflow"
ADMIN_USER="admin"
ADMIN_PASS="$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 20)"
if [[ ${#ADMIN_PASS} -lt 12 ]]; then
  ADMIN_PASS="$(openssl rand -hex 16)"
fi
LANGFLOW_SECRET_KEY=$(openssl rand -base64 48 | tr -d '\n')
CPU_CORES="$(nproc 2>/dev/null || echo 2)"
if [[ "${CPU_CORES}" -ge 8 ]]; then
  LANGFLOW_WORKERS_DEFAULT=4
elif [[ "${CPU_CORES}" -ge 4 ]]; then
  LANGFLOW_WORKERS_DEFAULT=2
else
  LANGFLOW_WORKERS_DEFAULT=1
fi
cat <<EOF2 >/opt/langflow/.env
LANGFLOW_CONFIG_DIR=/opt/langflow/data
LANGFLOW_SAVE_DB_IN_CONFIG_DIR=true
LANGFLOW_DATABASE_URL=sqlite:////opt/langflow/data/langflow.db
LANGFLOW_SECRET_KEY=${LANGFLOW_SECRET_KEY}
LANGFLOW_AUTO_LOGIN=false
LANGFLOW_SUPERUSER=${ADMIN_USER}
LANGFLOW_SUPERUSER_PASSWORD=${ADMIN_PASS}
LANGFLOW_HOST=0.0.0.0
LANGFLOW_PORT=7860
LANGFLOW_OPEN_BROWSER=false
LANGFLOW_LOG_LEVEL=info
DO_NOT_TRACK=true
LANGFLOW_REMOVE_API_KEYS=true
LANGFLOW_FALLBACK_TO_ENV_VAR=false
LANGFLOW_STORE_ENVIRONMENT_VARIABLES=false
LANGFLOW_WORKERS=${LANGFLOW_WORKERS_DEFAULT}
LANGFLOW_WORKER_TIMEOUT=300
LANGFLOW_HEALTH_CHECK_MAX_RETRIES=5
LANGFLOW_LAZY_LOAD_COMPONENTS=false
EOF2
chmod 600 /opt/langflow/.env
{
  echo "${APP_NAME} Credentials"
  echo "Default Admin User: ${ADMIN_USER}"
  echo "Username: ${ADMIN_USER}"
  echo "Password: ${ADMIN_PASS}"
  echo "Exposed Port: 7860"
  echo "URL: http://${LOCAL_IP}:7860"
} >~/langflow.creds
chmod 600 ~/langflow.creds
msg_ok "Configured Langflow"

msg_info "Creating Service"
cat <<'EOF2' >/etc/systemd/system/langflow.service
[Unit]
Description=Langflow Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/langflow
EnvironmentFile=/opt/langflow/.env
ExecStart=/opt/langflow/.venv/bin/langflow run --env-file /opt/langflow/.env --no-open-browser
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF2
systemctl daemon-reload
systemctl enable -q --now langflow
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
