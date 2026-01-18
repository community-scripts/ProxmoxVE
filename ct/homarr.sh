#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ) | Co-Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://homarr.dev/

APP="homarr"
var_tags="${var_tags:-arr;dashboard}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/homarr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "homarr" "homarr-labs/homarr"; then
    msg_info "Stopping Services (Patience)"
    systemctl stop homarr
    systemctl stop redis-server
    msg_ok "Services Stopped"

    if ! { grep -q '^REDIS_IS_EXTERNAL=' /opt/homarr/.env 2>/dev/null || grep -q '^REDIS_IS_EXTERNAL=' /opt/homarr.env 2>/dev/null; }; then
      msg_info "Fixing old structure"
      systemctl disable -q --now nginx
      cp /opt/homarr/.env /opt/homarr.env
      echo "REDIS_IS_EXTERNAL='true'" >> /opt/homarr.env
      sed -i '/^\[Unit\]/a Requires=redis-server.service\nAfter=redis-server.service' /etc/systemd/system/homarr.service
      sed -i 's|^ExecStart=.*|ExecStart=/opt/homarr/run.sh|' /etc/systemd/system/homarr.service
      sed -i 's|^EnvironmentFile=.*|EnvironmentFile=-/opt/homarr.env|' /etc/systemd/system/homarr.service
      chown -R redis:redis /appdata/redis
      chmod 744 /appdata/redis
      mkdir -p /etc/systemd/system/redis-server.service.d/
      cat <<EOF >/etc/systemd/system/redis-server.service.d/override.conf
[Service]
ReadWritePaths=-/appdata/redis -/var/lib/redis -/var/log/redis -/var/run/redis -/etc/redis
EOF
      systemctl daemon-reload
      rm /opt/run_homarr.sh
      msg_ok "Fixed old structure"
    fi

    msg_info "Updating Nodejs"
    $STD apt update
    $STD apt upgrade nodejs -y
    msg_ok "Updated Nodejs"

    NODE_VERSION=$(curl -s https://raw.githubusercontent.com/homarr-labs/homarr/dev/package.json | jq -r '.engines.node | split(">=")[1] | split(".")[0]')
    setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "homarr" "homarr-labs/homarr" "prebuild" "latest" "/opt/homarr" "build-debian-amd64.tar.gz"

    msg_info "Updating Homarr"
    cp /opt/homarr/redis.conf /etc/redis/redis.conf
    rm /etc/nginx/nginx.conf
    cp /opt/homarr/nginx.conf /etc/nginx/templates/nginx.conf
    msg_ok "Updated Homarr"

    msg_info "Starting Services"
    chmod +x /opt/homarr/run.sh
    systemctl start homarr
    systemctl start redis-server
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7575${CL}"
