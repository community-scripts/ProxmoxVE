#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://netboxlabs.com/

APP="NetBox"
var_tags="${var_tags:-network}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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
  if [[ ! -f /etc/systemd/system/netbox.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/netbox-community/netbox/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then

    msg_info "Stopping Service"
    systemctl stop netbox netbox-rq
    msg_ok "Stopped Service"

    msg_info "Updating $APP to v${RELEASE}"
    mv /opt/netbox/ /opt/netbox-backup
    cd /opt
    curl -fsSL "https://github.com/netbox-community/netbox/archive/refs/tags/v${RELEASE}.zip" -o $(basename "https://github.com/netbox-community/netbox/archive/refs/tags/v${RELEASE}.zip")
    $STD unzip "v${RELEASE}.zip"
    mv /opt/netbox-${RELEASE}/ /opt/netbox/

    cp -r /opt/netbox-backup/netbox/netbox/configuration.py /opt/netbox/netbox/netbox/
    cp -r /opt/netbox-backup/netbox/media/ /opt/netbox/netbox/
    cp -r /opt/netbox-backup/netbox/scripts /opt/netbox/netbox/
    cp -r /opt/netbox-backup/netbox/reports /opt/netbox/netbox/
    cp -r /opt/netbox-backup/gunicorn.py /opt/netbox/

    if [ -f /opt/netbox-backup/local_requirements.txt ]; then
      cp -r /opt/netbox-backup/local_requirements.txt /opt/netbox/
    fi

    if [ -f /opt/netbox-backup/netbox/netbox/ldap_config.py ]; then
      cp -r /opt/netbox-backup/netbox/netbox/ldap_config.py /opt/netbox/netbox/netbox/
    fi

    $STD /opt/netbox/upgrade.sh
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated $APP to v${RELEASE}"

    msg_info "Starting Service"
    systemctl start netbox netbox-rq
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -r "/opt/v${RELEASE}.zip"
    rm -r /opt/netbox-backup
    msg_ok "Cleaned"
    msg_ok "Updated successfully!"
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
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}${CL}"
