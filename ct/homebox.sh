#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck | Co-Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://homebox.software/en/

APP="HomeBox"
var_tags="${var_tags:-inventory;household}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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
  if [[ ! -f /etc/systemd/system/homebox.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if [[ -x /opt/homebox ]]; then
    sed -i 's|WorkingDirectory=/opt$|WorkingDirectory=/opt/homebox|' /etc/systemd/system/homebox.service
    sed -i 's|ExecStart=/opt/homebox$|ExecStart=/opt/homebox/homebox|' /etc/systemd/system/homebox.service
    sed -i 's|EnvironmentFile=/opt/.env$|EnvironmentFile=/opt/homebox/.env|' /etc/systemd/system/homebox.service
    systemctl daemon-reload
  fi

  if check_for_gh_release "homebox" "sysadminsmedia/homebox"; then
    msg_info "Stopping Service"
    systemctl stop homebox
    msg_ok "Stopped Service"

    if [ -f /opt/homebox ] && [ -x /opt/homebox ]; then
      rm -f /opt/homebox
    fi
    fetch_and_deploy_gh_release "homebox" "sysadminsmedia/homebox" "prebuild" "latest" "/opt/homebox" "homebox_Linux_x86_64.tar.gz"
    chmod +x /opt/homebox/homebox
    [ -f /opt/.env ] && mv /opt/.env /opt/homebox/.env
    [ -d /opt/.data ] && mv /opt/.data /opt/homebox/.data

    msg_info "Starting Service"
    systemctl start homebox
    msg_ok "Started Service"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7745${CL}"
