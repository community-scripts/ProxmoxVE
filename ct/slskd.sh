#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/slskd/slskd, https://soularr.net

APP="slskd"
var_tags="${var_tags:-arr;p2p}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
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

  if [[ ! -d /opt/slskd ]] || [[ ! -d /opt/soularr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -s https://api.github.com/repos/slskd/slskd/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    msg_info "Stopping $APP"
    systemctl stop slskd soularr.timer soularr.service
    msg_ok "Stopped $APP"

    msg_info "Updating $APP to v${RELEASE}"
    tmp_file=$(mktemp)
    curl -fsSL "https://github.com/slskd/slskd/releases/download/${RELEASE}/slskd-${RELEASE}-linux-x64.zip" -o $tmp_file
    $STD unzip -oj $tmp_file slskd -d /opt/${APP}
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated $APP to v${RELEASE}"

    msg_info "Starting $APP"
    systemctl start slskd
    msg_ok "Started $APP"
    rm -rf $tmp_file
  else
    msg_ok "No ${APP} update required. ${APP} is already at v${RELEASE}"
  fi
  msg_info "Updating Soularr"
  cp /opt/soularr/config.ini /opt/config.ini.bak
  cp /opt/soularr/run.sh /opt/run.sh.bak
  cd /tmp
  rm -rf /opt/soularr
  curl -fsSL -o main.zip https://github.com/mrusse/soularr/archive/refs/heads/main.zip
  $STD unzip main.zip
  mv soularr-main /opt/soularr
  cd /opt/soularr
  $STD pip install -r requirements.txt
  mv /opt/config.ini.bak /opt/soularr/config.ini
  mv /opt/run.sh.bak /opt/soularr/run.sh
  msg_ok "Updated soularr"

  msg_info "Starting soularr timer"
  systemctl start soularr.timer
  msg_ok "Started soularr timer"

  msg_info "Cleaning Up"
  rm -rf /tmp/main.zip
  msg_ok "Cleanup Completed"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5030${CL}"
