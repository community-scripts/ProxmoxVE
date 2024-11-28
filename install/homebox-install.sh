#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/sysadminsmedia/homebox

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc
msg_ok "Installed Dependencies"

msg_info "Installing Homebox"
RELEASE=$(curl -s https://api.github.com/repos/sysadminsmedia/homebox/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
wget -qO- https://github.com/sysadminsmedia/homebox/releases/download/${RELEASE}/homebox_Linux_x86_64.tar.gz | tar -xzf - -C /opt
chmod +x /opt/homebox
cat <<EOF >/opt/.env
# For possible environment variables check here: https://homebox.software/en/configure-homebox
HBOX_MODE=production
HBOX_WEB_PORT=7745
HBOX_WEB_HOST=0.0.0.0
EOF
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed Homebox"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/homebox.service
[Unit]
Description=Start Homebox Service
After=network.target

[Service]
WorkingDirectory=/opt
ExecStart=/opt/homebox
EnvironmentFile=/opt/.env
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now homebox.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
