#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Andy Grunwald (andygrunwald)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/hansmi/prometheus-paperless-exporter

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

msg_info "Installing Prometheus Paperless NGX Exporter"
RELEASE=$(curl -s https://api.github.com/repos/hansmi/prometheus-paperless-exporter/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q https://github.com/hansmi/prometheus-paperless-exporter/releases/download/v${RELEASE}/prometheus-paperless-exporter_${RELEASE}_linux_amd64.tar.gz
tar -xf prometheus-paperless-exporter_${RELEASE}_linux_amd64.tar.gz
mv prometheus-paperless-exporter_${RELEASE}_linux_amd64/prometheus-paperless-exporter /usr/local/bin/
mkdir -p /etc/prometheus-paperless-ngx-exporter
cat <<EOF > /etc/prometheus-paperless-ngx-exporter/paperless_auth_token_file
SECRET_AUTH_TOKEN
EOF
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed Prometheus Paperless NGX Exporter"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/prometheus-paperless-ngx-exporter.service
[Unit]
Description=Prometheus Paperless NGX Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=root
Restart=always
Type=simple
ExecStart=/usr/local/bin/prometheus-paperless-exporter \
    --paperless_url=http://paperless.example.org \
    --paperless_auth_token_file=/etc/prometheus-paperless-ngx-exporter/paperless_auth_token_file
ExecReload=/bin/kill -HUP \$MAINPID

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now prometheus-paperless-ngx-exporter
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
rm -rf prometheus-paperless-exporter_${RELEASE}_linux_amd64/ prometheus-paperless-exporter_${RELEASE}_linux_amd64.tar.gz
msg_ok "Cleaned"
