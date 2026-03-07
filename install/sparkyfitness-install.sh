#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Tom Frenzel (tomfrenzel)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/CodeWithCJ/SparkyFitness

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y nginx
msg_ok "Installed Dependencies"

PG_VERSION="18" setup_postgresql
PG_DB_NAME="sparkyfitness" PG_DB_USER="sparky" PG_DB_GRANT_SUPERUSER="true" setup_postgresql_db

fetch_and_deploy_gh_release sparkyfitness "CodeWithCJ/SparkyFitness" "tarball" "latest"

PNPM_VERSION="$(jq -r '.packageManager | split("@")[1]' /opt/sparkyfitness/package.json)"
NODE_VERSION="25" NODE_MODULE="pnpm@${PNPM_VERSION}" setup_nodejs

msg_info "Configuring Sparky Fitness"
mkdir -p "/etc/sparkyfitness" "/var/lib/sparkyfitness/uploads" "/var/lib/sparkyfitness/backup" "/var/www/sparkyfitness"
cp "/opt/sparkyfitness/docker/.env.example" "/etc/sparkyfitness/.env"
sed \
  -i \
  -e "s|^#\?SPARKY_FITNESS_DB_HOST=.*|SPARKY_FITNESS_DB_HOST=localhost|" \
  -e "s|^#\?SPARKY_FITNESS_DB_PORT=.*|SPARKY_FITNESS_DB_PORT=5432|" \
  -e "s|^SPARKY_FITNESS_DB_NAME=.*|SPARKY_FITNESS_DB_NAME=sparkyfitness|" \
  -e "s|^SPARKY_FITNESS_DB_USER=.*|SPARKY_FITNESS_DB_USER=sparky|" \
  -e "s|^SPARKY_FITNESS_DB_PASSWORD=.*|SPARKY_FITNESS_DB_PASSWORD=${PG_DB_PASS}|" \
  -e "s|^SPARKY_FITNESS_APP_DB_USER=.*|SPARKY_FITNESS_APP_DB_USER=sparky_app|" \
  -e "s|^SPARKY_FITNESS_APP_DB_PASSWORD=.*|SPARKY_FITNESS_APP_DB_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c20)|" \
  -e "s|^SPARKY_FITNESS_SERVER_HOST=.*|SPARKY_FITNESS_SERVER_HOST=localhost|" \
  -e "s|^SPARKY_FITNESS_SERVER_PORT=.*|SPARKY_FITNESS_SERVER_PORT=3010|" \
  -e "s|^SPARKY_FITNESS_FRONTEND_URL=.*|SPARKY_FITNESS_FRONTEND_URL=http://${LOCAL_IP}:80|" \
  -e "s|^SPARKY_FITNESS_API_ENCRYPTION_KEY=.*|SPARKY_FITNESS_API_ENCRYPTION_KEY=$(openssl rand -hex 32)|" \
  -e "s|^BETTER_AUTH_SECRET=.*|BETTER_AUTH_SECRET=$(openssl rand -hex 32)|" \
  "/etc/sparkyfitness/.env"
msg_ok "Configured Sparky Fitness"

msg_info "Building Backend"
cd /opt/sparkyfitness/SparkyFitnessServer
$STD npm install
msg_ok "Built Backend"

msg_info "Building Frontend (Patience)"
cd /opt/sparkyfitness/SparkyFitnessFrontend
$STD pnpm install
$STD pnpm run build
cp -a /opt/sparkyfitness/SparkyFitnessFrontend/dist/. /var/www/sparkyfitness/
msg_ok "Built Frontend"

msg_info "Creating SparkyFitness Service"
cat <<EOF >/etc/systemd/system/sparkyfitness-server.service
[Unit]
Description=SparkyFitness Backend Service
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
WorkingDirectory=/opt/sparkyfitness/SparkyFitnessServer
EnvironmentFile=/etc/sparkyfitness/.env
ExecStart=/usr/bin/node SparkyFitnessServer.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now sparkyfitness-server
msg_ok "Created SparkyFitness Service"

msg_info "Configuring Nginx"
sed \
  -e 's|${SPARKY_FITNESS_SERVER_HOST}|127.0.0.1|g' \
  -e 's|${SPARKY_FITNESS_SERVER_PORT}|3010|g' \
  -e 's|root /usr/share/nginx/html;|root /var/www/sparkyfitness;|g' \
  -e 's|server_name localhost;|server_name _;|g' \
  "/opt/sparkyfitness/docker/nginx.conf" >/etc/nginx/sites-available/sparkyfitness
ln -sf /etc/nginx/sites-available/sparkyfitness /etc/nginx/sites-enabled/sparkyfitness
rm -f /etc/nginx/sites-enabled/default
$STD nginx -t
$STD systemctl enable -q --now nginx
$STD systemctl reload nginx
msg_ok "Configured Nginx"

read -r -p "${TAB3}Would you like to install the SparkyFitness Garmin microservice? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  PYTHON_VERSION="3.13" setup_uv
  msg_info "Setting up SparkyFitness Garmin microservice"
  cd /opt/sparkyfitness/SparkyFitnessGarmin
  $STD uv venv --clear /opt/sparkyfitness/SparkyFitnessGarmin/.venv
  $STD uv pip install -r /opt/sparkyfitness/SparkyFitnessGarmin/requirements.txt
  sed -i -e "s|^#\?GARMIN_MICROSERVICE_URL=.*|GARMIN_MICROSERVICE_URL=http://${LOCAL_IP}:8000|" "/etc/sparkyfitness/.env"
  cat <<EOF >/etc/systemd/system/sparkyfitness-garmin.service
[Unit]
Description=SparkyFitness Garmin Microservice
After=network.target sparkyfitness-server.service
Requires=sparkyfitness-server.service

[Service]
Type=simple
WorkingDirectory=/opt/sparkyfitness/SparkyFitnessGarmin
EnvironmentFile=/etc/sparkyfitness/.env
ExecStart=/opt/sparkyfitness/SparkyFitnessGarmin/.venv/bin/python3 -m uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now sparkyfitness-garmin
  systemctl restart sparkyfitness-server
  msg_ok "Setup SparkyFitness Garmin microservice"
fi

motd_ssh
customize
cleanup_lxc
