#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.bazarr.media/

APP="Bazarr"
var_tags="${var_tags:-arr}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /var/lib/bazarr/ ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "bazarr" "morpheus65535/bazarr"; then
    PYTHON_VERSION="3.13" setup_uv
    fetch_and_deploy_gh_release "bazarr" "morpheus65535/bazarr" "prebuild" "latest" "/opt/bazarr" "bazarr.zip"

    msg_info "Setup Bazarr"
    mkdir -p /var/lib/bazarr/
    chmod 775 /opt/bazarr /var/lib/bazarr/
    sed -i.bak 's/--only-binary=Pillow//g' /opt/bazarr/requirements.txt
    $STD uv pip install -r /opt/bazarr/requirements.txt --system
    msg_ok "Setup Bazarr"
    msg_ok "Updated Successfully"
  fi
  exit
}
start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6767${CL}"
