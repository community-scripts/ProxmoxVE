#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/teslamate-org/teslamate

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  erlang \
  erlang-dev \
  erlang-syntax-tools \
  mosquitto \
  locales
sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen
$STD locale-gen
systemctl enable -q --now mosquitto
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "elixir" "elixir-lang/elixir" "prebuild" "latest" "/opt/elixir" "elixir-otp-27.zip"
for bin in elixir elixirc iex mix; do
  ln -sf "/opt/elixir/bin/$bin" "/usr/local/bin/$bin"
done

PG_VERSION="17" setup_postgresql
PG_DB_NAME="teslamate" PG_DB_USER="teslamate" PG_DB_GRANT_SUPERUSER="true" setup_postgresql_db
NODE_VERSION="22" setup_nodejs

setup_deb822_repo \
  "grafana" \
  "https://apt.grafana.com/gpg.key" \
  "https://apt.grafana.com" \
  "stable" \
  "main"

msg_info "Installing Grafana"
$STD apt install -y grafana
msg_ok "Installed Grafana"

fetch_and_deploy_gh_release "teslamate" "teslamate-org/teslamate" "tarball"

msg_info "Building TeslaMate (Patience)"
cd /opt/teslamate
export MIX_ENV=prod
$STD mix local.hex --force
$STD mix local.rebar --force
$STD mix deps.get --only prod
$STD npm install --prefix ./assets
$STD npm run deploy --prefix ./assets
$STD mix do phx.digest, release --overwrite
msg_ok "Built TeslaMate"

msg_info "Configuring TeslaMate"
cat <<EOF >/opt/teslamate.env
HOME=/opt/teslamate
LANG=en_US.UTF-8
LC_CTYPE=en_US.UTF-8
TZ=UTC
PORT=4000
ENCRYPTION_KEY=$(openssl rand -hex 32)
DATABASE_USER=teslamate
DATABASE_PASS=${PG_DB_PASS}
DATABASE_NAME=teslamate
DATABASE_HOST=127.0.0.1
DATABASE_PORT=5432
MQTT_HOST=127.0.0.1
EOF
chmod 600 /opt/teslamate.env
msg_ok "Configured TeslaMate"

msg_info "Provisioning Grafana"
mkdir -p /etc/grafana/provisioning/{datasources,dashboards}
cat <<EOF >/etc/grafana/provisioning/datasources/teslamate.yml
apiVersion: 1

datasources:
  - name: TeslaMate
    type: postgres
    url: 127.0.0.1:5432
    user: teslamate
    access: proxy
    isDefault: true
    secureJsonData:
      password: ${PG_DB_PASS}
    jsonData:
      postgresVersion: 1700
      sslmode: disable
      database: teslamate
    version: 1
    editable: true
EOF

cat <<EOF >/etc/grafana/provisioning/dashboards/teslamate.yml
apiVersion: 1

providers:
  - name: "teslamate"
    orgId: 1
    folder: TeslaMate
    folderUid: Nr4ofiDZk
    type: file
    disableDeletion: false
    allowUiUpdates: true
    updateIntervalSeconds: 86400
    options:
      path: /opt/teslamate/grafana/dashboards
      foldersFromFilesStructure: false
  - name: "teslamate_internal"
    orgId: 1
    folder: Internal
    folderUid: Nr5ofiDZk
    type: file
    disableDeletion: false
    allowUiUpdates: true
    updateIntervalSeconds: 86400
    options:
      path: /opt/teslamate/grafana/dashboards/internal
  - name: "teslamate_reports"
    orgId: 1
    folder: Reports
    folderUid: Nr6ofiDZk
    type: file
    disableDeletion: false
    allowUiUpdates: true
    updateIntervalSeconds: 86400
    options:
      path: /opt/teslamate/grafana/dashboards/reports
EOF

cat <<EOF >/etc/grafana/grafana.ini
[analytics]
reporting_enabled = false
check_for_updates = false
check_for_plugin_updates = false

[security]
allow_embedding = true
disable_gravatar = true

[users]
allow_sign_up = false

[dashboards]
default_home_dashboard_path = /opt/teslamate/grafana/dashboards/internal/home.json

[date_formats]
use_browser_locale = true
EOF
systemctl enable -q --now grafana-server
msg_ok "Provisioned Grafana"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/teslamate.service
[Unit]
Description=TeslaMate
Wants=network-online.target
After=network-online.target postgresql.service mosquitto.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/teslamate
EnvironmentFile=/opt/teslamate.env
ExecStartPre=/opt/teslamate/_build/prod/rel/teslamate/bin/teslamate eval "TeslaMate.Release.migrate"
ExecStart=/opt/teslamate/_build/prod/rel/teslamate/bin/teslamate start
ExecStop=/opt/teslamate/_build/prod/rel/teslamate/bin/teslamate stop
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now teslamate
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
