#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://dqops.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  python3 \
  python3-pip \
  python3-venv \
  curl \
  wget \
  gnupg \
  software-properties-common
msg_ok "Installed Dependencies"

msg_info "Creating DQOps User"
useradd -r -s /bin/bash -d /opt/dqops dqops
mkdir -p /opt/dqops
chown dqops:dqops /opt/dqops
msg_ok "Created DQOps User"

msg_info "Installing DQOps"
sudo -u dqops python3 -m pip install --user dqops
echo 'export PATH=$PATH:/opt/dqops/.local/bin' >> /opt/dqops/.bashrc
msg_ok "Installed DQOps"

msg_info "Creating DQOps Service"
cat <<EOF >/etc/systemd/system/dqops.service
[Unit]
Description=DQOps Data Quality Operations Center
After=network.target

[Service]
Type=simple
User=dqops
Group=dqops
WorkingDirectory=/opt/dqops
Environment=PATH=/opt/dqops/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=HOME=/opt/dqops
Environment=DQO_USER_HOME=/opt/dqops/.dqops
ExecStart=/opt/dqops/.local/bin/dqo --server --headless
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable dqops
msg_ok "Created DQOps Service"

msg_info "Starting DQOps for Initial Setup"
sudo -u dqops -H /opt/dqops/.local/bin/dqo &
DQOPS_PID=$!
sleep 30
kill $DQOPS_PID 2>/dev/null || true
wait $DQOPS_PID 2>/dev/null || true
msg_ok "Initial Setup Completed"

msg_info "Starting DQOps Service"
systemctl start dqops
msg_ok "Started DQOps Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"