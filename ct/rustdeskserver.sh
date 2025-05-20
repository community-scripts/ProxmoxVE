#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rustdesk/rustdesk-server

APP="RustDesk Server"
TAGS="remote-desktop"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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

  if [[ ! -x /usr/bin/hbbr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if [[ ! -f /opt/rustdeskapi_version.txt ]]; then
    touch /opt/rustdeskapi_version.txt
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  APIRELEASE=$(curl -fsSL https://api.github.com/repos/lejianwen/rustdesk-api/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ "${RELEASE}" != "$(cat /opt/rustdesk_version.txt)" ]] || [[ "${APIRELEASE}" != "$(cat /opt/rustdesk-api.txt)" ]] || [[ ! -f /opt/rustdesk_version.txt ]] || [[ ! -f /opt/rustdesk-api.txt ]]; then
    msg_info "Stopping $APP"
    systemctl stop rustdesk-hbbr
    systemctl stop rustdesk-hbbs
    if [[ -f /lib/systemd/system/rustdesk-api.service ]]; then
      systemctl stop rustdesk-api
    fi
    msg_ok "Stopped $APP"

    msg_info "Updating $APP to v${RELEASE}"
    TEMPDIR=$(mktemp -d)
    curl -fsSL "https://github.com/rustdesk/rustdesk-server/releases/download/${RELEASE}/rustdesk-server-hbbr_${RELEASE}_amd64.deb" \
      -o "${TEMPDIR}/rustdesk-server-hbbr_${RELEASE}_amd64.deb"
    curl -fsSL "https://github.com/rustdesk/rustdesk-server/releases/download/${RELEASE}/rustdesk-server-hbbs_${RELEASE}_amd64.deb" \
      -o "${TEMPDIR}/rustdesk-server-hbbs_${RELEASE}_amd64.deb"
    curl -fsSL "https://github.com/rustdesk/rustdesk-server/releases/download/${RELEASE}/rustdesk-server-utils_${RELEASE}_amd64.deb" \
      -o "${TEMPDIR}/rustdesk-server-utils_${RELEASE}_amd64.deb"
    curl -fsSL "https://github.com/lejianwen/rustdesk-api/releases/download/v${APIRELEASE}/rustdesk-api-server_${APIRELEASE}_amd64.deb" \
      -o "${TEMPDIR}/rustdesk-api-server_${APIRELEASE}_amd64.deb"
    $STD dpkg -i $TEMPDIR/*.deb
    echo "${RELEASE}" >/opt/rustdesk_version.txt
    echo "${APIRELEASE}" >/opt/rustdeskapi_version.txt
    msg_ok "Updated $APP to v${RELEASE}"

    msg_info "Cleaning Up"
    rm -rf $TEMPDIR
    msg_ok "Cleanup Completed"

    msg_info "Starting services"
    systemctl start -q rustdesk-* --all
    msg_ok "Services started"
    msg_ok "Update Successful"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}${IP}:21114${CL}"
