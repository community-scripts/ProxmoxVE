#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.zabbix.com/

APP="Zabbix"
var_tags="${var_tags:-monitoring}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
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
  if [[ ! -f /etc/zabbix/zabbix_server.conf ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Stopping ${APP} Services"
  systemctl stop zabbix-server zabbix-agent2
  msg_ok "Stopped ${APP} Services"

  msg_info "Updating $APP LXC"
  mkdir -p /opt/zabbix-backup/
  cp /etc/zabbix/zabbix_server.conf /opt/zabbix-backup/
  cp /etc/apache2/conf-enabled/zabbix.conf /opt/zabbix-backup/
  cp -R /usr/share/zabbix/ /opt/zabbix-backup/
  #cp -R /usr/share/zabbix-* /opt/zabbix-backup/ Remove temporary
  rm -Rf /etc/apt/sources.list.d/zabbix.list
  cd /tmp
  curl -fsSL "$(curl -fsSL https://repo.zabbix.com/zabbix/ |
    grep -oP '(?<=href=")[0-9]+\.[0-9]+(?=/")' | sort -V | tail -n1 |
    xargs -I{} echo "https://repo.zabbix.com/zabbix/{}/release/debian/pool/main/z/zabbix-release/zabbix-release_latest+debian12_all.deb")" \
    -o /tmp/zabbix-release_latest+debian12_all.deb
  $STD dpkg -i zabbix-release_latest+debian12_all.deb
  $STD apt-get update
  $STD apt-get install --only-upgrade zabbix-server-pgsql zabbix-frontend-php zabbix-agent2 zabbix-agent2-plugin-*

  msg_info "Starting ${APP} Services"
  systemctl start zabbix-server zabbix-agent2
  systemctl restart apache2
  msg_ok "Started ${APP} Services"

  msg_info "Cleaning Up"
  rm -rf /tmp/zabbix-release_latest+debian12_all.deb
  msg_ok "Cleaned"
  msg_ok "Updated Successfully"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}/zabbix${CL}"
