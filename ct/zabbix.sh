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

  . /etc/os-release
  if [ "$VERSION_CODENAME" != "trixie" ]; then
    msg_error "Unsupported Debian version: $VERSION_CODENAME – please upgrade to Debian 13 (Trixie) before updating Zabbix."
    exit
  fi

  if systemctl list-unit-files | grep -q zabbix-agent2.service; then
    AGENT_SERVICE="zabbix-agent2"
  else
    AGENT_SERVICE="zabbix-agent"
  fi

  msg_info "Stopping Services"
  systemctl stop zabbix-server
  systemctl stop "$AGENT_SERVICE"
  msg_ok "Stopped Services"

  msg_info "Updating Zabbix"
  mkdir -p /opt/zabbix-backup/
  cp /etc/zabbix/zabbix_server.conf /opt/zabbix-backup/
  cp /etc/apache2/conf-enabled/zabbix.conf /opt/zabbix-backup/
  cp -R /usr/share/zabbix/ /opt/zabbix-backup/

  rm -Rf /etc/apt/sources.list.d/zabbix.list
  cd /tmp
  curl -fsSL "$(curl -fsSL https://repo.zabbix.com/zabbix/ |
    grep -oP '(?<=href=")[0-9]+\.[0-9]+(?=/")' | sort -V | tail -n1 |
    xargs -I{} echo "https://repo.zabbix.com/zabbix/{}/release/debian/pool/main/z/zabbix-release/zabbix-release_latest+debian13_all.deb")" \
    -o /tmp/zabbix-release_latest+debian13_all.deb
  $STD dpkg -i zabbix-release_latest+debian13_all.deb
  $STD apt update

  $STD apt install --only-upgrade zabbix-server-pgsql zabbix-frontend-php php8.4-pgsql

  if [ "$AGENT_SERVICE" = "zabbix-agent2" ]; then
    $STD apt install --only-upgrade zabbix-agent2 zabbix-agent2-plugin-postgresql
    if [ -f /etc/zabbix/zabbix_agent2.d/plugins.d/nvidia.conf ]; then
      sed -i 's|^Plugins.NVIDIA.System.Path=.*|# Plugins.NVIDIA.System.Path=/usr/libexec/zabbix/zabbix-agent2-plugin-nvidia-gpu|' \
        /etc/zabbix/zabbix_agent2.d/plugins.d/nvidia.conf
    fi
  else
    $STD apt install --only-upgrade zabbix-agent
  fi

  if command -v fping >/dev/null 2>&1; then
    FPING_PATH=$(command -v fping)
    sed -i "s|^#\?FpingLocation=.*|FpingLocation=$FPING_PATH|" /etc/zabbix/zabbix_server.conf
  fi
  if command -v fping6 >/dev/null 2>&1; then
    FPING6_PATH=$(command -v fping6)
    sed -i "s|^#\?Fping6Location=.*|Fping6Location=$FPING6_PATH|" /etc/zabbix/zabbix_server.conf
  fi
  msg_ok "Updated Zabbix"

  msg_info "Starting Services"
  systemctl start zabbix-server
  systemctl start "$AGENT_SERVICE"
  systemctl restart apache2
  msg_ok "Started Services"

  msg_info "Cleaning Up"
  rm -rf /tmp/zabbix-release_latest+debian13_all.deb
  $STD apt -y autoremove
  $STD apt -y autoclean
  $STD apt -y clean
  msg_ok "Cleaned"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}/zabbix${CL}"
