#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://openarchiver.com/

APP="Open-Archiver"
var_tags="${var_tags:-os}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-3072}"
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
  if [[ ! -d /opt/openarchiver ]]; then
    msg_error "No Open Archiver Installation Found!"
    exit
  fi

  if check_for_gh_release "openarchiver" "LogicLabs-OU/OpenArchiver"; then
    msg_info "Stopping Services"
    systemctl stop openarchiver
    msg_ok "Stopped Services"

    cp /opt/openarchiver/.env /opt/openarchiver.env
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "openarchiver" "LogicLabs-OU/OpenArchiver" "tarball" "latest" "/opt/openarchiver"
    mv /opt/openarchiver.env /opt/openarchiver/.env

    msg_info "Updating Open Archiver"
    cd /opt/openarchiver
    $STD pnpm install --shamefully-hoist --frozen-lockfile --prod=false
    $STD pnpm run build:oss
    $STD pnpm db:migrate
    msg_ok "Updated Open Archiver"

    if grep -q '^ExecStart=/usr/bin/pnpm docker-start$' /etc/systemd/system/openarchiver.service; then
      sed -i 's|^ExecStart=/usr/bin/pnpm docker-start$|ExecStart=/usr/bin/pnpm docker-start:oss|' /etc/systemd/system/openarchiver.service
      systemctl daemon-reload
    fi

    msg_info "Starting Services"
    systemctl start openarchiver
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
