#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/remz1337/ProxmoxVE/remz/misc/build.func)
# Copyright (c) 2021-2025 remz1337
# Authors: remz1337
# License: MIT | https://github.com/remz1337/ProxmoxVE/raw/remz/LICENSE
# Source: https://github.com/browser-use/browser-use

APP="browser-use"
var_tags="${var_tags:-AI}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_ipv6_method="${var_ipv6_method:-disable}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -f /etc/systemd/system/browser-use.service ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_error "To update browser-use, create a new container and transfer your configuration."
    exit
}

start
build_container
description

# msg_info "Setting Container to Normal Resources"
# pct set $CTID -memory 2048
# pct set $CTID -cores 2
# msg_ok "Set Container to Normal Resources"
msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"