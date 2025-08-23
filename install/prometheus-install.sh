#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://prometheus.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "prometheus" "prometheus/prometheus" "prebuild" "latest" "/usr/local/bin" "*linux-amd64.tar.gz"

msg_info "Installing Prometheus"
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus
mv /usr/local/bin/prometheus.yml /etc/prometheus/prometheus.yml
msg_ok "Installed Prometheus"

msg_info "Creating Service"
cat <<'EOF' >/etc/systemd/system/prometheus.service
[Unit]
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
ExecReload=/bin/kill -HUP \$MAINPID

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now prometheus
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
