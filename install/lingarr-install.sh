#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/lingarr-translate/lingarr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PG_VERSION="17" setup_postgresql
PG_DB_NAME="lingarr" PG_DB_USER="lingarr" setup_postgresql_db
NODE_VERSION="24" setup_nodejs

DOTNET_VERSION="10" DOTNET_TYPE="sdk" setup_dotnet

fetch_and_deploy_gh_release "lingarr" "lingarr-translate/lingarr" "tarball"

msg_info "Building Lingarr (Patience)"
cd /opt/lingarr/Lingarr.Client
$STD npm ci
$STD npm run build
mkdir -p /opt/lingarr/Lingarr.Server/wwwroot
cp -r /opt/lingarr/Lingarr.Client/dist/* /opt/lingarr/Lingarr.Server/wwwroot/
cd /opt/lingarr
export DOTNET_CLI_TELEMETRY_OPTOUT=1
$STD dotnet publish ./Lingarr.Server/Lingarr.Server.csproj -c Release -o /opt/lingarr_app /p:UseAppHost=false /p:Version="$(cat ~/.lingarr)"
msg_ok "Built Lingarr"

msg_info "Configuring Lingarr"
mkdir -p /opt/lingarr_data/{config,plugins}
cat <<EOF >/opt/lingarr.env
ASPNETCORE_ENVIRONMENT=Production
ASPNETCORE_URLS=http://+:9876
ASPNETCORE_HTTP_PORTS=9876

DB_CONNECTION=postgresql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=lingarr
DB_USERNAME=lingarr
DB_PASSWORD=${PG_DB_PASS}

PLUGINS_PATH=/opt/lingarr_data/plugins
DOTNET_CLI_TELEMETRY_OPTOUT=1

# Translation backend. Alternatives: openai, deepl, anthropic, gemini, localai
SERVICE_TYPE=libretranslate
LIBRE_TRANSLATE_URL=http://CHANGE_ME:5000
EOF
chmod 600 /opt/lingarr.env
msg_ok "Configured Lingarr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/lingarr.service
[Unit]
Description=Lingarr
Wants=network-online.target
After=network-online.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/lingarr_app
EnvironmentFile=/opt/lingarr.env
ExecStart=/usr/bin/dotnet /opt/lingarr_app/Lingarr.Server.dll
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now lingarr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
