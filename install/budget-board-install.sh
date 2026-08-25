#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/teelur/budget-board

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y nginx
setup_deb822_repo \
  "microsoft" \
  "https://packages.microsoft.com/keys/microsoft-2025.asc" \
  "https://packages.microsoft.com/debian/13/prod/" \
  "trixie"
$STD apt install -y dotnet-sdk-10.0
msg_ok "Installed Dependencies"

NODE_VERSION=25 setup_nodejs
PG_VERSION=16 setup_postgresql
PG_DB_NAME=budget_board_db PG_DB_USER=budget_board setup_postgresql_db

fetch_and_deploy_gh_release "budget-board" "teelur/budget-board" "tarball"

msg_info "Configuring Budget Board Backend"
cd /opt/budget-board/server
$STD dotnet restore "BudgetBoard.WebAPI/BudgetBoard.WebAPI.csproj"
export configuration=Release
$STD dotnet publish "BudgetBoard.WebAPI/BudgetBoard.WebAPI.csproj" -c $configuration -o /opt/budget-board/publish /p:UseAppHost=false --no-restore

cat <<EOF >/opt/budget-board/budget-board.env
Logging__LogLevel__Default=Information
CLIENT_ADDRESS=$LOCAL_IP
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DATABASE=$PG_DB_NAME
POSTGRES_USER=$PG_DB_USER
POSTGRES_PASSWORD=$PG_DB_PASS
OIDC_ENABLED=false
OIDC_ISSUER=
OIDC_CLIENT_ID=
OIDC_CLIENT_SECRET=
EMAIL_SENDER=
EMAIL_SENDER_USERNAME=
EMAIL_SENDER_PASSWORD=
EMAIL_SMTP_HOST=
EMAIL_SMTP_PORT=587
DISABLE_NEW_USERS=false
DISABLE_LOCAL_AUTH=false
AUTO_UPDATE_DB=true
DISABLE_AUTO_SYNC=false
SYNC_INTERVAL_HOURS=8
TZ=UTC

ASPNETCORE_URLS=http://127.0.0.1:6253
PORT=6253
VITE_SERVER_ADDRESS=${LOCAL_IP}
VITE_OIDC_ENABLED=false
VITE_OIDC_PROVIDER=
VITE_OIDC_CLIENT_ID=
VITE_DISABLE_NEW_USERS=false
VITE_DISABLE_LOCAL_AUTH=false
EOF
msg_ok "Configured Budget Board Backend"

msg_info "Configuring Budget Board Frontend"
cd /opt/budget-board/client
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
$STD yarn config set --home enableTelemetry 0
$STD npm install --global corepack@latest
$STD corepack enable
$STD yarn install
$STD yarn run build
cp -r dist/. /var/www/html/
msg_ok "Configured Budget Board Frontend"

msg_info "Creating services"
cat <<EOF >/etc/systemd/system/budget-board.service
[Unit]
Description=Budget Board Service
After=network.target

[Service]
WorkingDirectory=/opt/budget-board/publish
ExecStart=dotnet BudgetBoard.WebAPI.dll
Restart=always
EnvironmentFile=/opt/budget-board/budget-board.env

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now budget-board

cat <<'EOF' >/etc/nginx/sites-available/budget-board.conf
server {
    listen 80 default_server;
    server_name _;
    root /var/www/html;
    index index.html;

    location /api/ {
        proxy_pass http://127.0.0.1:6253;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF
nginx_enable_site budget-board.conf
msg_ok "Created services"

motd_ssh
customize
cleanup_lxc
