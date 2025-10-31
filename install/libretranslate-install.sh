#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/LibreTranslate/LibreTranslate

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing dependencies"
$STD apt install -y \
  pkg-config \
  build-essential \
  g++ \
  cmake \
  libprotobuf-dev \
  protobuf-compiler \
  libsentencepiece-dev \
  libicu-dev
msg_ok "Installed dependencies"

msg_info "Setup Python3"
$STD apt install -y \
  python3-pip \
  python3-dev \
  python3-icu
msg_ok "Setup Python3"

setup_uv
fetch_and_deploy_gh_release "libretranslate" "LibreTranslate/LibreTranslate"

msg_info "Setup LibreTranslate (Patience)"
TORCH_VERSION=$(grep -Eo '"torch ==[0-9]+\.[0-9]+\.[0-9]+' /opt/libretranslate/pyproject.toml | \
  tail -n1 | sed 's/.*==//')
if [[ -z "$TORCH_VERSION" ]]; then
  TORCH_VERSION="2.5.0"
fi
cd /opt/libretranslate
$STD uv venv .venv
$STD source .venv/bin/activate
$STD uv pip install --upgrade pip setuptools
$STD uv pip install Babel==2.12.1
$STD .venv/bin/python scripts/compile_locales.py
$STD uv pip install "torch==${TORCH_VERSION}" --extra-index-url https://download.pytorch.org/whl/cpu
$STD uv pip install "numpy<2"
$STD uv pip install .
$STD uv pip install libretranslate
$STD .venv/bin/python scripts/install_models.py

cat <<EOF >/opt/libretranslate/.env
LT_PORT=5000
EOF
msg_ok "Installed LibreTranslate"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/libretranslate.service
[Unit]
Description=LibreTranslate
After=network.target

[Service]
User=root
Type=idle
Restart=always
Environment="PATH=/usr/local/lib/python3.11/dist-packages/libretranslate"
EnvironmentFile=/opt/libretranslate/.env
ExecStart=/opt/libretranslate/.venv/bin/python3 /opt/libretranslate/.venv/bin/libretranslate --host * --update-models
ExecReload=/bin/kill -s HUP
KillMode=mixed
TimeoutStopSec=1

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now libretranslate
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
