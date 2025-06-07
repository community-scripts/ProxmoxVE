#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Andy Grunwald (andygrunwald)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/prometheus-pve/prometheus-pve-exporter

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PYTHON_VERSION="3.12" setup_uv

msg_info "Installing Prometheus Proxmox VE Exporter"
mkdir -p /opt/prometheus-pve-exporter
cd /opt/prometheus-pve-exporter

$STD uv venv /opt/prometheus-pve-exporter/.venv
$STD /opt/prometheus-pve-exporter/.venv/bin/python -m ensurepip --upgrade
$STD /opt/prometheus-pve-exporter/.venv/bin/python -m pip install --upgrade pip
$STD /opt/prometheus-pve-exporter/.venv/bin/python -m pip install prometheus-pve-exporter
cat <<EOF >/opt/prometheus-pve-exporter/pve.yml
default:
    user: prometheus@pve
    password: sEcr3T!
    verify_ssl: false
EOF
msg_ok "Installed Prometheus Proxmox VE Exporter"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/prometheus-pve-exporter.service
[Unit]
Description=Prometheus Proxmox VE Exporter
Documentation=https://github.com/znerol/prometheus-pve-exporter
After=syslog.target network.target

[Service]
User=root
Restart=always
Type=simple
ExecStart=/opt/prometheus-pve-exporter/.venv/bin/pve_exporter \
    --config.file=/opt/prometheus-pve-exporter/pve.yml \
    --web.listen-address=0.0.0.0:9221
ExecReload=/bin/kill -HUP \$MAINPID

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now prometheus-pve-exporter
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
