#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.craftycontrol.com/pages/getting-started/installation/linux/

APP="Crafty-Controller"
var_tags="${var_tags:-gaming}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-16}"
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
  if [[ ! -d /opt/crafty-controller ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gl_release "Crafty-Controller" "crafty-controller/crafty-4"; then
    msg_info "Stopping Crafty-Controller"
    systemctl stop crafty-controller
    msg_ok "Stopped Crafty-Controller"

    create_backup \
      "/opt/crafty-controller/crafty/crafty-4/app/config/db" \
      "/opt/crafty-controller/crafty/crafty-4/app/config/config.json" \
      "/opt/crafty-controller/crafty/crafty-4/app/config/web" \
      "/opt/crafty-controller/crafty/crafty-4/servers" \
      "/opt/crafty-controller/crafty/crafty-4/backups" \
      "/opt/crafty-controller/crafty/crafty-4/import"

    CLEAN_INSTALL=1 fetch_and_deploy_gl_release "Crafty-Controller" "crafty-controller/crafty-4" "tarball" "latest" "/opt/crafty-controller/crafty/crafty-4"

    restore_backup

    msg_info "Updating TemurinJDK"
    setup_java
    $STD apt install -y temurin-{8,11,17,21,25}-jre
    $STD update-alternatives --set java /usr/lib/jvm/temurin-25-jre-$(arch_resolve)/bin/java
    msg_ok "Updated TemurinJDK"

    msg_info "Updating Python dependencies"
    chown -R crafty:crafty /opt/crafty-controller
    cd /opt/crafty-controller/crafty/crafty-4
    $STD sudo -u crafty bash -c '
      source /opt/crafty-controller/crafty/.venv/bin/activate
      pip3 install --no-cache-dir -r requirements.txt
    '
    msg_ok "Updated Python dependencies"

    msg_info "Starting Crafty-Controller"
    systemctl start crafty-controller
    msg_ok "Started Crafty-Controller"

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
echo -e "${GATEWAY}${BGN}https://${IP}:8443${CL}"
