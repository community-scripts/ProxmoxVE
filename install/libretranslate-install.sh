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
$STD apt-get install -y --no-install-recommends \
  pkg-config \
  gcc \
  g++ \
  libicu-dev
msg_ok "Installed dependencies"

msg_info "Setup Python3"
$STD apt-get install -y \
  python3-pip \
  python3-dev \
  python3-icu
msg_ok "Setup Python3"

setup_uv
fetch_and_deploy_gh_release "libretranslate" "LibreTranslate/LibreTranslate"

msg_info "Setup LibreTranslate (Patience)"
cd /opt/libretranslate
$STD uv venv .venv
$STD source .venv/bin/activate
$STD uv pip install --upgrade pip setuptools
$STD uv pip install Babel==2.12.1
$STD .venv/bin/python scripts/compile_locales.py
$STD uv pip install torch==2.2.0 --extra-index-url https://download.pytorch.org/whl/cpu
$STD uv pip install "numpy<2"
$STD uv pip install .
$STD uv pip install libretranslate
$STD .venv/bin/python scripts/install_models.py
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
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
