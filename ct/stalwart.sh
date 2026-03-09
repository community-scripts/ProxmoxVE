#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/remz1337/ProxmoxVE/remz/misc/build.func)
# Copyright (c) 2021-2026 remz1337
# Author: remz1337
# License: MIT | https://github.com/remz1337/ProxmoxVE/raw/remz/LICENSE
# Source: https://github.com/stalwartlabs/stalwart

APP="Stalwart"
var_tags="${var_tags:-email}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
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

  if [[ ! -f /opt/stalwart ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "stalwart" "stalwartlabs/stalwart"; then
    msg_info "Stopping service"
    systemctl stop stalwart
    msg_ok "Service stopped"

    msg_info "Updating service"
    /opt/stalwart/bin/stalwart --config /opt/stalwart/etc/config.toml --export /opt/stalwart/export
    chown -R stalwart:stalwart /opt/stalwart/export
    rm -rf /opt/stalwart/bin/stalwart
    fetch_and_deploy_gh_release "stalwart" "stalwartlabs/stalwart" "singlefile" "latest" "/opt/stalwart/bin" "stalwart-x86_64-unknown-linux-gnu"
    chmod +x /opt/stalwart/bin/stalwart
	msg_ok "Updated service"

    msg_info "Starting service"
    systemctl start stalwart
    msg_ok "Started service"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080/login${CL}"
