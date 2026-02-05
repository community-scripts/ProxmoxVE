#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Andy Grunwald (andygrunwald)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/hansmi/prometheus-paperless-exporter

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "prom-paperless-exp" "hansmi/prometheus-paperless-exporter" "binary"

msg_info "Configuring Prometheus Paperless NGX Exporter"
mkdir -p /etc/prometheus-paperless-ngx-exporter
echo "SECRET_AUTH_TOKEN" >/etc/prometheus-paperless-ngx-exporter/paperless_auth_token_file
msg_ok "Configured Prometheus Paperless NGX Exporter"

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
ExecStart=/usr/bin/prometheus-paperless-exporter \
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
cleanup_lxc
