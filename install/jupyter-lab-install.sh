#!/usr/bin/env bash

# Copyright (c) 2024 itssujee
# Author: itssujee
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y git
$STD apt-get install -y python3
$STD apt-get install -y python3-pip
$STD apt-get install -y nodejs
msg_ok "Installed Dependencies"

IP=$(hostname -I | awk '{print $1}')

msg_info "Installing JupyterLab"
$STD pip3 install jupyterlab jupyter-lsp
$STD mkdir -p /root/.jupyter/
cat <<EOF >/root/.jupyter/jupyter_server_config.json
{
  "IdentityProvider": {
    "hashed_password": "argon2:\$argon2id\$v=19\$m=10240,t=10,p=8\$OQvpqeCTN7ZtaIuLKVfr9g\$dBp51EMnXw0wmgheJa4pKH3US/ODZaz6LDwlAMdNTAM"
  }
}
EOF
cat <<EOF >/etc/systemd/system/jupyterlab.service
[Unit]
Description=Jupyter Lab
[Service]
Type=simple
WorkingDirectory=/root
ExecStart=jupyter lab --ip $IP --port=8080 --no-browser --allow-root
Restart=always
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now jupyterlab.service
msg_ok "Installed JupyterLab"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"