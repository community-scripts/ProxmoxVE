#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: FWiegerinck
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/smallstep/certificates

# App Default Values
APP="Alpine-Step-CA"
var_tags="${var_tags:-alpine;step-ca}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.22}"
var_unprivileged="${var_unprivileged:-1}"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  if [[ ! -f /etc/step-ca/config/ca.json ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_error "There is currently no official automatic update process for ${APP}.\n \
  Updates may require manual intervention and migrations.\n \
  Please consult the Smallstep documentation before attempting to update."
  exit
}

# Build
start
build_container
description

# Completion Message
msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO} The CA will be configured on first boot inside the container."
