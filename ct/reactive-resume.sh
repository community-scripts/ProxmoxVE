#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream | MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://rxresume.org | Github: https://github.com/amruthpillai/reactive-resume

APP="Reactive-Resume"
var_tags="${var_tags:-documents}"
var_cpu="${var_cpu:-2}"
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

  if [[ ! -f /etc/systemd/system/reactive-resume.service ]]; then
    msg_error "No $APP Installation Found!"
    exit
  fi
  if check_for_gh_release "reactive-resume" "amruthpillai/reactive-resume"; then
    msg_info "Stopping services"
    systemctl stop reactive-resume
    msg_ok "Stopped services"

    cp /opt/reactive-resume/.env /opt/reactive-resume.env.bak
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "reactive-resume" "amruthpillai/reactive-resume" "tarball" "latest" "/opt/reactive-resume"

    msg_info "Updating Reactive Resume (Patience)"
    cd /opt/reactive-resume
    export CI="true"
    export NODE_ENV="production"
    $STD pnpm install --frozen-lockfile
    $STD pnpm run build
    mv /opt/reactive-resume.env.bak /opt/reactive-resume/.env
    msg_ok "Updated Reactive Resume"

    msg_info "Restarting services"
    systemctl start chromium-printer reactive-resume
    msg_ok "Restarted services"
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
