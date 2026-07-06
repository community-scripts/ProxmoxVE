#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: gVNS (ggfevans)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/RackulaLives/Rackula

APP="Rackula"
var_tags="${var_tags:-homelab}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/rackula ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  if check_for_gh_release "rackula" "RackulaLives/Rackula"; then
    msg_info "Stopping Services"
    systemctl stop rackula-api nginx
    msg_ok "Stopped Services"

    create_backup /opt/rackula/data
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "rackula" "RackulaLives/Rackula" "prebuild" "latest" "/opt/rackula" "rackula-lxc-*.tar.gz"
    restore_backup

    msg_info "Updating Configuration"
    cp /opt/rackula/config/nginx.conf /etc/nginx/sites-available/rackula
    cp /opt/rackula/config/security-headers.conf /etc/nginx/snippets/security-headers.conf
    cp /opt/rackula/config/rackula-api.service /etc/systemd/system/rackula-api.service
    if grep -q '^User=' /etc/systemd/system/rackula-api.service; then
      sed -i 's/^User=.*/User=root/' /etc/systemd/system/rackula-api.service
    else
      sed -i '/^\[Service\]/a User=root' /etc/systemd/system/rackula-api.service
    fi
    if grep -q '^Group=' /etc/systemd/system/rackula-api.service; then
      sed -i 's/^Group=.*/Group=root/' /etc/systemd/system/rackula-api.service
    else
      sed -i '/^\[Service\]/a Group=root' /etc/systemd/system/rackula-api.service
    fi
    mkdir -p /etc/systemd/system/nginx.service.d
    cp /opt/rackula/config/nginx.service.d-override.conf /etc/systemd/system/nginx.service.d/override.conf
    chown -R root:root /opt/rackula/frontend
    find /opt/rackula/frontend -type d -exec chmod 755 {} \;
    find /opt/rackula/frontend -type f -exec chmod 644 {} \;
    chmod 750 /opt/rackula/data
    msg_ok "Updated Configuration"

    msg_info "Starting Services"
    $STD nginx -t
    systemctl daemon-reload
    systemctl start nginx rackula-api
    msg_ok "Started Services"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
