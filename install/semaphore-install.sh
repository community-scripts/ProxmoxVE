#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: kristocopani
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://semaphoreui.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y git
msg_ok "Installed Dependencies"

msg_info "Setting up Ansible"
curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" | gpg --dearmor -o /usr/share/keyrings/ansible-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu jammy main" >/etc/apt/sources.list.d/ansible.list
$STD apt update
$STD apt install -y ansible
msg_ok "Set up Ansible"

fetch_and_deploy_gh_release "semaphore" "semaphoreui/semaphore" "binary"

msg_info "Configuring Semaphore"
mkdir -p /opt/semaphore
cd /opt/semaphore
SEM_HASH=$(openssl rand -base64 32)
SEM_ENCRYPTION=$(openssl rand -base64 32)
SEM_KEY=$(openssl rand -base64 32)
SEM_PW=$(openssl rand -base64 12)
cat <<EOF >/opt/semaphore/config.json
{
  "bolt": {
    "host": "/opt/semaphore/semaphore_db.bolt"
  },
  "tmp_path": "/opt/semaphore/tmp",
  "cookie_hash": "${SEM_HASH}",
  "cookie_encryption": "${SEM_ENCRYPTION}",
  "access_key_encryption": "${SEM_KEY}"
}
EOF
$STD semaphore user add --admin --login admin --email admin@helper-scripts.com --name Administrator --password "${SEM_PW}" --config /opt/semaphore/config.json
echo "${SEM_PW}" >~/semaphore.creds
msg_ok "Setup Semaphore"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/semaphore.service
[Unit]
Description=Semaphore UI
Documentation=https://docs.semaphoreui.com/
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/bin/semaphore server --config /opt/semaphore/config.json
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now semaphore
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
