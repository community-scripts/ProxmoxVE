#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
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
UBUNTU_CODENAME=jammy
wget -qO- "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" | gpg --dearmour >/usr/share/keyrings/ansible-archive-keyring.gpg
$STD echo "deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu $UBUNTU_CODENAME main" | tee /etc/apt/sources.list.d/ansible.list
$STD apt update 
$STD apt install -y \
ansible
msg_ok "Installed Dependencies"

msg_info "Installing Semaphore"
RELEASE=$(curl -s https://api.github.com/repos/semaphoreui/semaphore/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
mkdir -p /opt/semaphore
cd /opt/semaphore
wget -q https://github.com/semaphoreui/semaphore/releases/download/v${RELEASE}/semaphore_${RELEASE}_linux_amd64.deb
$STD dpkg -i semaphore_${RELEASE}_linux_amd64.deb  
rm -rf semaphore_${RELEASE}_linux_amd64.deb 

json_cookie_hash=$(head -c32 /dev/urandom | base64)
json_cookie_encryption=$(head -c32 /dev/urandom | base64)
json_access_key_encryption=$(head -c32 /dev/urandom | base64)
cat <<EOF >/opt/semaphore/config.json
{
  "bolt": {
    "host": "/opt/semaphore/semaphore_db.bolt"
  },
  "tmp_path": "/opt/semaphore/tmp",
  "cookie_hash": "${json_cookie_hash}",
  "cookie_encryption": "${json_cookie_encryption}",
  "access_key_encryption": "${json_access_key_encryption}"
}
EOF
$STD semaphore user add --admin --login admin --email admin@example.com --name Administrator --password admin --config /opt/semaphore/config.json
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed Semaphore"

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