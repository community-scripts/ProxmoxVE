#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: [Dave-code-creater (Tan Dat, Ta)]
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: [https://jupyter.org/]

# Import Functions und Setup
source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Installing Dependencies with the 3 core dependencies (curl;sudo;mc)
msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  python3 \
    python3-pip \

msg_ok "Ins talled Dependencies"

# Setup Application (Jupyter Notebook)"
msg_info "Setting up Jupyter Notebook"
pip3 install jupyter
msg_ok "Jupyter Notebook Installed"

msg_info "Creating Service"
cat << EOF >/etc/systemd/system/jupyternotebook.service
[Unit]
Description=Jupyter Notebook Server
After=network.target

[Service]
Type=simple
ExecStart=jupyter notebook --ip=0.0.0.0 --port=8888 --allow-root
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now jupyternotebook.service

motd_ssh
customize

# Cleanup
msg_info "Cleaning up"

$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

