#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: miviro
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/heiher/hev-socks5-server

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Setup ${APPLICATION}"
RELEASE=$(curl -fsSL https://api.github.com/repos/heiher/${APPLICATION}/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
curl -L -o "${APPLICATION}" "https://github.com/heiher/${APPLICATION}/releases/download/${RELEASE}/hev-socks5-server-linux-x86_64"
mv ${APPLICATION} /opt/${APPLICATION}
chmod +x /opt/${APPLICATION}
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
curl -L -o "main.yml" "https://raw.githubusercontent.com/heiher/${APPLICATION}/refs/heads/main/conf/main.yml"
sed -i 's/^#auth:/auth:/; s/^#  file: conf\/auth.txt/  file: \/root\/hev.creds/' main.yml
mkdir -p /etc/${APPLICATION}
USERNAME="admin"
PASSWORD=$(openssl rand -base64 16)
MARK="0"
echo "$USERNAME $PASSWORD $MARK" >/root/hev.creds
mv main.yml /etc/${APPLICATION}/main.yml
msg_ok "Setup ${APPLICATION}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/${APPLICATION}.service
[Unit]
Description=${APPLICATION} Service
After=network.target

[Service]
ExecStart=/opt/${APPLICATION} /etc/${APPLICATION}/main.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now ${APPLICATION}
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
