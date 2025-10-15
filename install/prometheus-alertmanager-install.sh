#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Andy Grunwald (andygrunwald)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://prometheus.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "alertmanager" "prometheus/alertmanager" "prebuild" "latest" "/usr/local/bin/" "alertmanager*linux-amd64.tar.gz"

msg_info "Configuring Prometheus Alertmanager"
mkdir -p /etc/alertmanager /var/lib/alertmanager
mv /usr/local/bin/alertmanager.yml /etc/alertmanager/alertmanager.yml
msg_ok "Configured Prometheus Alertmanager"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/prometheus-alertmanager.service
[Unit]
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
WantedBy=multi-user.target
EOF
systemctl enable -q --now prometheus-alertmanager
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
