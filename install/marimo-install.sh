#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/marimo-team/marimo

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PYTHON_VERSION="3.13" setup_uv

MARIMO_VERSION="${var_appversion:-$(get_latest_github_release "marimo-team/marimo")}"
msg_info "Installing marimo ${MARIMO_VERSION}"
$STD uv venv --python 3.13 /opt/marimo/.venv
$STD uv pip install --python /opt/marimo/.venv/bin/python "marimo[recommended]==${MARIMO_VERSION}" pandas
cat <<EOF >~/.marimo
${MARIMO_VERSION}
EOF
msg_ok "Installed marimo ${MARIMO_VERSION}"

msg_info "Configuring marimo"
mkdir -p /opt/marimo_data/notebooks /root/.config/marimo
cat <<EOF >/opt/marimo_data/.env
MARIMO_TOKEN_PASSWORD=${var_token_password:-$(random_password)}
EOF
chmod 600 /opt/marimo_data/.env
cat <<EOF >/root/.config/marimo/marimo.toml
[package_management]
manager = "uv"
EOF
msg_ok "Configured marimo"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/marimo.service
[Unit]
Description=marimo
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/marimo_data/notebooks
EnvironmentFile=/opt/marimo_data/.env
Environment=MARIMO_SKIP_UPDATE_CHECK=1
ExecStart=/opt/marimo/.venv/bin/marimo -y edit --headless --host 0.0.0.0 --port 2718 --token-password \${MARIMO_TOKEN_PASSWORD} /opt/marimo_data/notebooks
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now marimo
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
