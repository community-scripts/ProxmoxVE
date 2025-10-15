#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/slskd/slskd/, https://soularr.net

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  python3-pip
msg_ok "Installed Dependencies"

msg_info "Setup ${APPLICATION}"
tmp_file=$(mktemp)
RELEASE=$(curl -s https://api.github.com/repos/slskd/slskd/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
curl -fsSL "https://github.com/slskd/slskd/releases/download/${RELEASE}/slskd-${RELEASE}-linux-x64.zip" -o $tmp_file
$STD unzip $tmp_file -d /opt/${APPLICATION}
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
JWT_KEY=$(openssl rand -base64 44)
SLSKD_API_KEY=$(openssl rand -base64 44)
cp /opt/${APPLICATION}/config/slskd.example.yml /opt/${APPLICATION}/config/slskd.yml
sed -i \
  -e "\|web:|,\|cidr|s|^#||" \
  -e "\|https:|,\|5031|s|false|true|" \
  -e "\|api_keys|,\|cidr|s|<some.*$|$SLSKD_API_KEY|; \
    s|role: readonly|role: readwrite|; \
    s|0.0.0.0/0,::/0|& # Replace this with your subnet|" \
  -e "\|soulseek|,\|write_queue|s|^#||" \
  -e "\|jwt:|,\|ttl|s|key: ~|key: $JWT_KEY|" \
  -e "s|^   picture|#   picture|" \
  /opt/${APPLICATION}/config/slskd.yml
msg_ok "Setup ${APPLICATION}"

msg_info "Installing Soularr"
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
cd /tmp
curl -fsSL -o main.zip https://github.com/mrusse/soularr/archive/refs/heads/main.zip
$STD unzip main.zip
mv soularr-main /opt/soularr
cd /opt/soularr
$STD pip install -r requirements.txt
sed -i \
  -e "\|[Slskd]|,\|host_url|s|yourslskdapikeygoeshere|$SLSKD_API_KEY|" \
  -e "/host_url/s/slskd/localhost/" \
  /opt/soularr/config.ini
sed -i \
  -e "/#This\|#Default\|INTERVAL/{N;d;}" \
  -e "/while\|#Pass/d" \
  -e "\|python|s|app|opt/soularr|; s|python|python3|" \
  -e "/dt/,+2d" \
  /opt/soularr/run.sh
sed -i -E "/(soularr.py)/s/.{5}$//; /if/,/fi/s/.{4}//" /opt/soularr/run.sh
chmod +x /opt/soularr/run.sh
msg_ok "Installed Soularr"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/${APPLICATION}.service
[Unit]
Description=${APPLICATION} Service
After=network.target
Wants=network.target

[Service]
WorkingDirectory=/opt/${APPLICATION}
ExecStart=/opt/${APPLICATION}/slskd --config /opt/${APPLICATION}/config/slskd.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/soularr.timer
[Unit]
Description=Soularr service timer
RefuseManualStart=no
RefuseManualStop=no

[Timer]
Persistent=true
# run every 5 minutes
OnCalendar=*-*-* *:0/5:00
Unit=soularr.service

[Install]
WantedBy=timers.target
EOF

cat <<EOF >/etc/systemd/system/soularr.service
[Unit]
Description=Soularr service
After=network.target slskd.service

[Service]
Type=simple
WorkingDirectory=/opt/soularr
ExecStart=/bin/bash -c /opt/soularr/run.sh

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now ${APPLICATION}
systemctl enable -q soularr.timer
msg_ok "Created Services"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf $tmp_file
rm -rf /tmp/main.zip
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
