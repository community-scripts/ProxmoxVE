#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/chroma-core/chroma

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PYTHON_VERSION="3.12" setup_uv

CHROMA_VERSION="${var_appversion:-$(curl -fsSL https://pypi.org/pypi/chromadb/json | jq -r '.info.version')}"
msg_info "Installing Chroma ${CHROMA_VERSION}"
$STD uv venv --python 3.12 /opt/chroma/.venv
$STD uv pip install --python /opt/chroma/.venv/bin/python "chromadb==${CHROMA_VERSION}"
cat <<EOF >~/.chroma
${CHROMA_VERSION}
EOF
msg_ok "Installed Chroma ${CHROMA_VERSION}"

msg_info "Configuring Chroma"
mkdir -p /opt/chroma_data
cat <<EOF >/opt/chroma_data/config.yaml
persist_path: "/opt/chroma_data"
listen_address: "0.0.0.0"
port: 8000
EOF
msg_ok "Configured Chroma"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/chroma.service
[Unit]
Description=Chroma
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/chroma_data
ExecStart=/opt/chroma/.venv/bin/chroma run /opt/chroma_data/config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now chroma
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
