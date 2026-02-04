#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
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

  if check_for_gh_release "netbox" "netbox-community/netbox"; then
    msg_info "Stopping Services"
    systemctl stop netbox netbox-rq
    msg_ok "Stopped Services"

    msg_info "Backing up NetBox configurations"
    mv /opt/netbox/ /opt/netbox-backup
    msg_ok "Backed up NetBox configurations"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "netbox" "netbox-community/netbox" "tarball"

    cp -r /opt/netbox-backup/netbox/netbox/configuration.py /opt/netbox/netbox/netbox/
    cp -r /opt/netbox-backup/netbox/{media,scripts,reports}/ /opt/netbox/netbox/
    cp -r /opt/netbox-backup/gunicorn.py /opt/netbox/
    [[ -f /opt/netbox-backup/local_requirements.txt ]] && cp -r /opt/netbox-backup/local_requirements.txt /opt/netbox/
    [[ -f /opt/netbox-backup/netbox/netbox/ldap_config.py ]] && cp -r /opt/netbox-backup/netbox/netbox/ldap_config.py /opt/netbox/netbox/netbox/

    $STD /opt/netbox/upgrade.sh
    rm -r /opt/netbox-backup

    msg_info "Starting Services"
    systemctl start netbox netbox-rq
    msg_ok "Started Services"
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
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}${CL}"
