#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/odoo/odoo

APP="Odoo"
var_tags="${var_tags:-erp}"
var_disk="${var_disk:-6}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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

  if [[ ! -f /etc/odoo/odoo.conf ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if ! [[ $(dpkg -s python3-lxml-html-clean 2>/dev/null) ]]; then
    $STD apt install python3-lxml
    curl -fsSL "http://archive.ubuntu.com/ubuntu/pool/universe/l/lxml-html-clean/python3-lxml-html-clean_0.1.1-1_all.deb" -o /opt/python3-lxml-html-clean.deb
    $STD dpkg -i /opt/python3-lxml-html-clean.deb
    rm -f /opt/python3-lxml-html-clean.deb
  fi

  RELEASE=$(curl -fsSL https://nightly.odoo.com/ | grep -oE 'href="[0-9]+\.[0-9]+/nightly"' | head -n1 | cut -d'"' -f2 | cut -d/ -f1)
  LATEST_VERSION=$(curl -fsSL "https://nightly.odoo.com/${RELEASE}/nightly/deb/" |
    grep -oP "odoo_${RELEASE}\.\d+_all\.deb" |
    sed -E "s/odoo_(${RELEASE}\.[0-9]+)_all\.deb/\1/" |
    sort -V |
    tail -n1)

  if [[ "${LATEST_VERSION}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    msg_info "Stopping ${APP} service"
    systemctl stop odoo
    msg_ok "Stopped Service"

    msg_info "Updating ${APP} to ${LATEST_VERSION}"
    curl -fsSL https://nightly.odoo.com/${RELEASE}/nightly/deb/odoo_${RELEASE}.latest_all.deb -o /opt/odoo.deb
    $STD apt install -y /opt/odoo.deb
    echo "$LATEST_VERSION" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to ${LATEST_VERSION}"

    msg_info "Starting ${APP} service"
    systemctl start odoo
    msg_ok "Started Service"

    msg_info "Cleaning Up"
    rm -f /opt/odoo.deb
    msg_ok "Cleaned"

    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. ${APP} is already at ${LATEST_VERSION}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8069${CL}"
