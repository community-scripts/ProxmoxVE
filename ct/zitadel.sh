#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/remz1337/ProxmoxVE/remz/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: dave-yap (dave-yap)
# License: MIT | https://github.com/remz1337/ProxmoxVE/raw/remz/LICENSE
# Source: https://zitadel.com/

APP="Zitadel"
var_tags="${var_tags:-identity-provider}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
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
  if [[ ! -f /etc/systemd/system/zitadel.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "zitadel" "zitadel/zitadel"; then
    msg_info "Stopping Service"
    systemctl stop zitadel
    msg_ok "Stopped Service"

    msg_info "Updating Zitadel"
    rm -f /opt/zitadel/*
	fetch_and_deploy_gh_release "zitadel" "zitadel/zitadel" "prebuild" "latest" "/opt/zitadel" "zitadel-linux-amd64.tar.gz"

    rm -f /opt/login/*
	fetch_and_deploy_gh_release "login" "zitadel/zitadel" "prebuild" "latest" "${LOGIN_DIR}" "zitadel-login.tar.gz"

    cd /opt/zitadel
    ./zitadel setup --masterkeyFile /etc/zitadel/.masterkey --config /etc/zitadel/config.yaml --init-projections=true
	msg_ok "Updated Zitadel"

    msg_info "Starting Service"
    systemctl start zitadel
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_info "Setting Container to Normal Resources"
pct set $CTID -memory 1024
pct set $CTID -cores 1
msg_ok "Set Container to Normal Resources"

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080/ui/console${CL}"

echo -e "${INFO}${GN} Default Admin Credentials:${CL}"
echo -e "${INFO}${BL} Username: zitadel-admin@zitadel.localhost${CL}"
echo -e "${INFO}${BL} Password: Password1!${CL}"
echo -e "${INFO} All credentials are saved in: /etc/zitadel/INSTALLATION_INFO.txt${CL}"