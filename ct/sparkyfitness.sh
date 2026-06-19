#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Tom Frenzel (tomfrenzel)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/CodeWithCJ/SparkyFitness

APP="SparkyFitness"
var_tags="${var_tags:-health;fitness}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-7}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/sparkyfitness ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "sparkyfitness" "CodeWithCJ/SparkyFitness"; then
    msg_info "Stopping Services"
    systemctl stop sparkyfitness-server nginx
    msg_ok "Stopped Services"

    create_backup /opt/sparkyfitness/SparkyFitnessServer/uploads

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "sparkyfitness" "CodeWithCJ/SparkyFitness" "tarball"
    restore_backup

    PNPM_VERSION="$(jq -r '.packageManager | split("@")[1]' /opt/sparkyfitness/package.json)"
    NODE_VERSION="25" NODE_MODULE="pnpm@${PNPM_VERSION}" setup_nodejs

    msg_info "Updating Sparky Fitness Backend"
    cd /opt/sparkyfitness/SparkyFitnessServer
    $STD pnpm install
    msg_ok "Updated Sparky Fitness Backend"

    msg_info "Updating Sparky Fitness Frontend (Patience)"
    cd /opt/sparkyfitness
    $STD pnpm install
    cd /opt/sparkyfitness/SparkyFitnessFrontend
    $STD pnpm run build
    cp -a /opt/sparkyfitness/SparkyFitnessFrontend/dist/. /var/www/sparkyfitness/
    msg_ok "Updated Sparky Fitness Frontend"

    msg_info "Refreshing Nginx Config"
    sed \
      -e 's|${SPARKY_FITNESS_SERVER_HOST}|127.0.0.1|g' \
      -e 's|${SPARKY_FITNESS_SERVER_PORT}|3010|g' \
      -e 's|${NGINX_LISTEN_PORT}|80|g' \
      -e 's|${NGINX_ACCESS_LOG}|/var/log/nginx/sparkyfitness.access.log|g' \
      -e 's|${NGINX_ERROR_LOG}|/var/log/nginx/sparkyfitness.error.log|g' \
      -e 's|root /usr/share/nginx/html;|root /var/www/sparkyfitness;|g' \
      -e 's|server_name localhost;|server_name _;|g' \
      "/opt/sparkyfitness/docker/nginx.conf" >/etc/nginx/sites-available/sparkyfitness
    msg_ok "Refreshed Nginx Config"

    msg_info "Refreshing SparkyFitness Service"
    cat <<EOF >/etc/systemd/system/sparkyfitness-server.service
  [Unit]
  Description=SparkyFitness Backend Service
  After=network.target postgresql.service
  Requires=postgresql.service

  [Service]
  Type=simple
  WorkingDirectory=/opt/sparkyfitness/SparkyFitnessServer
  EnvironmentFile=/etc/sparkyfitness/.env
  ExecStart=/opt/sparkyfitness/SparkyFitnessServer/node_modules/.bin/tsx SparkyFitnessServer.js
  Restart=always
  RestartSec=5

  [Install]
  WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    msg_ok "Refreshed SparkyFitness Service"


    msg_info "Starting Services"
    $STD systemctl start sparkyfitness-server nginx
    msg_ok "Started Services"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
