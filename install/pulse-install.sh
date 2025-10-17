#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: rcourtman & vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rcourtman/Pulse

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  diffutils \
  polkitd
msg_ok "Installed Dependencies"

msg_info "Creating User"
if useradd -r -m -d /opt/pulse-home -s /usr/sbin/nologin pulse; then
  msg_ok "Created User"
else
  msg_error "User creation failed"
  exit 1
fi

mkdir -p /etc/pulse
fetch_and_deploy_gh_release "pulse" "rcourtman/Pulse" "prebuild" "latest" "/opt/pulse" "*-linux-amd64.tar.gz"
ln -sf /opt/pulse/bin/pulse /usr/local/bin/pulse
chown -R pulse:pulse /etc/pulse /opt/pulse
msg_ok "Installed Pulse"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/pulse.service
[Unit]
Description=Pulse Monitoring Server
After=network.target

[Service]
Type=simple
User=pulse
Group=pulse
WorkingDirectory=/opt/pulse
ExecStart=/opt/pulse/bin/pulse
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="PULSE_DATA_DIR=/etc/pulse"

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now pulse
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
