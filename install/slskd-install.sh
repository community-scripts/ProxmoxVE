#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/slskd/slskd/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "Slskd" "slskd/slskd" "prebuild" "latest" "/opt/slskd" "slskd-*-linux-x64.zip"

msg_info "Configuring Slskd"
JWT_KEY=$(openssl rand -base64 44)
SLSKD_API_KEY=$(openssl rand -base64 44)
cp /opt/slskd/config/slskd.example.yml /opt/slskd/config/slskd.yml
sed -i \
  -e '/web:/,/cidr/s/^# //' \
  -e '/https:/,/port: 5031/s/false/true/' \
  -e '/port: 5030/,/socket/s/,.*$//' \
  -e '/content_path:/,/authentication/s/false/true/' \
  -e "\|api_keys|,\|cidr|s|<some.*$|$SLSKD_API_KEY|; \
    s|role: readonly|role: readwrite|; \
    s|0.0.0.0/0,::/0|& # Replace this with your subnet|" \
  -e "\|jwt:|,\|ttl|s|key: ~|key: $JWT_KEY|" \
  -e '/soulseek/,/write_queue/s/^# //' \
  -e 's/^.*picture/#&/' /opt/slskd/config/slskd.yml
msg_ok "Configured Slskd"

# read -rp "${TAB3}Do you want to install Soularr? y/N " soularr
# if [[ ${soularr,,} =~ ^(y|yes)$ ]]; then
#   msg_info "Installing Dependencies"
#   $STD apt install -y python3-pip
#   msg_ok "Installed Dependencies"
#   cd /opt/soularr
#   $STD pip install -r requirements.txt
#   sed -i \
#     -e "\|[Slskd]|,\|host_url|s|yourslskdapikeygoeshere|$SLSKD_API_KEY|" \
#     -e "/host_url/s/slskd/localhost/" \
#     /opt/soularr/config.ini
#   sed -i \
#     -e "/#This\|#Default\|INTERVAL/{N;d;}" \
#     -e "/while\|#Pass/d" \
#     -e "\|python|s|app|opt/soularr|; s|python|python3|" \
#     -e "/dt/,+2d" \
#     /opt/soularr/run.sh
#   sed -i -E "/(soularr.py)/s/.{5}$//; /if/,/fi/s/.{4}//" /opt/soularr/run.sh
#   chmod +x /opt/soularr/run.sh
#   msg_ok "Installed Soularr"
# fi

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/slskd.service
[Unit]
Description=Slskd Service
After=network.target
Wants=network.target

[Service]
WorkingDirectory=/opt/slskd
ExecStart=/opt/slskd/slskd --config /opt/slskd/config/slskd.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# if [[ -d /opt/soularr ]]; then
#   cat <<EOF >/etc/systemd/system/soularr.timer
# [Unit]
# Description=Soularr service timer
# RefuseManualStart=no
# RefuseManualStop=no
#
# [Timer]
# Persistent=true
# # run every 5 minutes
# OnCalendar=*-*-* *:0/5:00
# Unit=soularr.service
#
# [Install]
# WantedBy=timers.target
# EOF
#
#   cat <<EOF >/etc/systemd/system/soularr.service
# [Unit]
# Description=Soularr service
# After=network.target slskd.service
#
# [Service]
# Type=simple
# WorkingDirectory=/opt/soularr
# ExecStart=/bin/bash -c /opt/soularr/run.sh
#
# [Install]
# WantedBy=multi-user.target
# EOF
#   msg_warn "Add your Lidarr API key to Soularr in '/opt/soularr/config.ini', then run 'systemctl enable --now soularr.timer'"
# fi
systemctl enable -q --now slskd
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
