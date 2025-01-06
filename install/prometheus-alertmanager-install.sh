#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Andy Grunwald (andygrunwald)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://prometheus.io/

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

msg_info "Installing Prometheus Alertmanager"
RELEASE=$(curl -s https://api.github.com/repos/prometheus/alertmanager/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
mkdir -p /etc/alertmanager
mkdir -p /var/lib/alertmanager
wget -q https://github.com/prometheus/alertmanager/releases/download/v${RELEASE}/alertmanager-${RELEASE}.linux-amd64.tar.gz
tar -xf alertmanager-${RELEASE}.linux-amd64.tar.gz
mv alertmanager-${RELEASE}.linux-amd64/alertmanager alertmanager-${RELEASE}.linux-amd64/amtool /usr/local/bin/
mv alertmanager-${RELEASE}.linux-amd64/alertmanager.yml /etc/alertmanager/alertmanager.yml
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed Prometheus Alertmanager"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/prometheus-alertmanager.service
echo "[Unit]
Description=Prometheus Alertmanager
Wants=network-online.target
After=network-online.target

[Service]
User=root
Restart=always
Type=simple
ExecStart=/usr/local/bin/alertmanager \
    --config.file=/etc/alertmanager/alertmanager.yml \
    --storage.path=/var/lib/alertmanager/ \
    --web.listen-address=0.0.0.0:9093
ExecReload=/bin/kill -HUP \$MAINPID

[Install]
WantedBy=multi-user.target"
EOF
systemctl enable -q --now prometheus-alertmanager
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
rm -rf alertmanager-${RELEASE}.linux-amd64 alertmanager-${RELEASE}.linux-amd64.tar.gz
msg_ok "Cleaned"
