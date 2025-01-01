#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: kristocopani
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  mc \
  git \
  gpg \
  sudo

wget -qO- "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" | gpg --dearmour >/usr/share/keyrings/ansible-archive-keyring.gpg
cat <<EOF >/etc/apt/sources.list.d/ansible.list
deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu jammy main
EOF
$STD apt update
$STD apt install -y ansible
msg_ok "Installed Dependencies"

msg_info "Setup Semaphore"
RELEASE=$(curl -s https://api.github.com/repos/semaphoreui/semaphore/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
mkdir -p /opt/semaphore
cd /opt/semaphore
wget -q https://github.com/semaphoreui/semaphore/releases/download/v${RELEASE}/semaphore_${RELEASE}_linux_amd64.deb
$STD dpkg -i semaphore_${RELEASE}_linux_amd64.deb

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

$STD semaphore user add --admin --login admin --email admin@helper-scripts.com --name Administrator --password ${SEM_PW} --config /opt/semaphore/config.json
echo "${SEM_PW}" >~/semaphore.creds
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
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

systemctl enable --now -q semaphore.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf semaphore_${RELEASE}_linux_amd64.deb
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"