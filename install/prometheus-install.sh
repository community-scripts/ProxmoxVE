#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
msg_ok "Installed Dependencies"

msg_info "Installing Prometheus"
RELEASE=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus
wget -q https://github.com/prometheus/prometheus/releases/download/v${RELEASE}/prometheus-${RELEASE}.linux-amd64.tar.gz
tar -xf prometheus-${RELEASE}.linux-amd64.tar.gz
cd prometheus-${RELEASE}.linux-amd64
mv prometheus promtool /usr/local/bin/
mv prometheus.yml /etc/prometheus/prometheus.yml
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed Prometheus"

msg_info "Creating Service"
service_path="/etc/systemd/system/prometheus.service"
echo "[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=root
Restart=always
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus/ \
    --web.listen-address=0.0.0.0:9090

[Install]
WantedBy=multi-user.target" >$service_path
systemctl enable -q --now prometheus
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
rm -rf ../prometheus-${RELEASE}.linux-amd64 ../prometheus-${RELEASE}.linux-amd64.tar.gz
msg_ok "Cleaned"
