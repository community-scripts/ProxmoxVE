#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/AnalogJ/scrutiny

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Setting up InfluxDB Repository"
setup_deb822_repo \
  "influxdata" \
  "https://repos.influxdata.com/influxdata-archive.key" \
  "https://repos.influxdata.com/debian" \
  "stable"
msg_ok "Set up InfluxDB Repository"

msg_info "Installing InfluxDB"
$STD apt install -y influxdb2
systemctl enable -q --now influxdb
for _ in {1..30}; do
  curl -fsS http://127.0.0.1:8086/health >/dev/null 2>&1 && break
  sleep 1
done
msg_ok "Installed InfluxDB"

msg_info "Configuring InfluxDB"
INFLUX_PASS="$(random_password)"
INFLUX_TOKEN="$(random_password 48)"
curl -fsS -X POST http://127.0.0.1:8086/api/v2/setup \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"admin\",\"password\":\"${INFLUX_PASS}\",\"org\":\"scrutiny\",\"bucket\":\"metrics\",\"token\":\"${INFLUX_TOKEN}\"}" >/dev/null
mkdir -p /opt/scrutiny_data
cat <<EOT >/opt/scrutiny_data/.env
INFLUXDB_USER=admin
INFLUXDB_PASSWORD=${INFLUX_PASS}
INFLUXDB_TOKEN=${INFLUX_TOKEN}
EOT
chmod 600 /opt/scrutiny_data/.env
msg_ok "Configured InfluxDB"

fetch_and_deploy_gh_release "scrutiny" "AnalogJ/scrutiny" "singlefile" "latest" "/opt/scrutiny" "scrutiny-web-linux-$(arch_resolve "amd64" "arm64")"
fetch_and_deploy_gh_release "scrutiny-web" "AnalogJ/scrutiny" "prebuild" "latest" "/opt/scrutiny/web" "scrutiny-web-frontend.tar.gz"

msg_info "Configuring Scrutiny"
cat <<EOT >/opt/scrutiny_data/scrutiny.yaml
version: 1
web:
  listen:
    port: 8080
    host: 0.0.0.0
    basepath: ''
  database:
    location: /opt/scrutiny_data/scrutiny.db
  src:
    frontend:
      path: /opt/scrutiny/web
  influxdb:
    scheme: 'http'
    host: 127.0.0.1
    port: 8086
    token: '${INFLUX_TOKEN}'
    org: 'scrutiny'
    bucket: 'metrics'
    retention_policy: true
log:
  file: ''
  level: INFO
EOT
chmod 600 /opt/scrutiny_data/scrutiny.yaml
msg_ok "Configured Scrutiny"

msg_info "Creating Service"
cat <<EOT >/etc/systemd/system/scrutiny.service
[Unit]
Description=Scrutiny
After=network-online.target influxdb.service
Requires=influxdb.service

[Service]
Type=simple
WorkingDirectory=/opt/scrutiny_data
ExecStart=/opt/scrutiny/scrutiny start --config /opt/scrutiny_data/scrutiny.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOT
systemctl enable -q --now scrutiny
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
