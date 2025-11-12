#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Dave-code-creater (Tan Dat, Ta)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://jupyter.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PYTHON_VERSION="3.12" setup_uv

msg_info "Installing Jupyter"
mkdir -p /opt/jupyter
cd /opt/jupyter
$STD uv venv /opt/jupyter/.venv
$STD /opt/jupyter/.venv/bin/python -m ensurepip --upgrade
$STD /opt/jupyter/.venv/bin/python -m pip install --upgrade pip
$STD /opt/jupyter/.venv/bin/python -m pip install jupyter
ln -s /opt/jupyter/.venv/bin/jupyter /usr/local/bin/jupyter
ln -s /opt/jupyter/.venv/bin/jupyter-lab /usr/local/bin/jupyter-lab
ln -s /opt/jupyter/.venv/bin/jupyter-notebook /usr/local/bin/jupyter-notebook
msg_ok "Installed Jupyter"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/jupyternotebook.service
[Unit]
Description=Jupyter Notebook Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/jupyter
ExecStart=/opt/jupyter/.venv/bin/jupyter notebook --ip=0.0.0.0 --port=8888 --allow-root
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now jupyternotebook
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
