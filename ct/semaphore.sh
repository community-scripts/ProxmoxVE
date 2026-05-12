#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: kristocopani
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://semaphoreui.com/ | Github: https://github.com/semaphoreui/semaphore

APP="Semaphore"
var_tags="${var_tags:-dev_ops}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /etc/systemd/system/semaphore.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "semaphore" "semaphoreui/semaphore"; then
    if [[ -f /opt/semaphore/semaphore_db.bolt ]]; then
      msg_warn "WARNING: Due to bugs with BoltDB database, update script will move your application"
      msg_warn "to use SQLite database instead. Make sure you have a backup of your data!"
      echo ""
      read -r -p "${TAB3}Do you want to continue? (y/N): " CONFIRM
      if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        exit 0
      else
        msg_info "Moving from BoltDB to SQLite"
        sed -i \
          -e 's|"bolt": {|"sqlite": {|' \
          -e 's|/semaphore_db.bolt"|/database.sqlite"|' \
          -e '/semaphore_db.bolt/d' \
          -e '/"dialect"/d' \
          -e '/^  },$/a\  "dialect": "sqlite",' \
          /opt/semaphore/config.json
        msg_ok "Moved from BoltDB to SQLite"
      fi
    fi

    msg_info "Stopping Service"
    systemctl stop semaphore
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "semaphore" "semaphoreui/semaphore" "binary" "latest" "/opt/semaphore" "semaphore_*_linux_amd64.deb"

    if [[ -f /opt/semaphore/semaphore_db.bolt ]]; then
      $STD semaphore migrate --from-boltdb /opt/semaphore/semaphore_db.bolt --config /opt/semaphore/config.json
      rm -f /opt/semaphore/semaphore_db.bolt
    fi

    msg_info "Starting Service"
    systemctl start semaphore
    msg_ok "Started Service"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
