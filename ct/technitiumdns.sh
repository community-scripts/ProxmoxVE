#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://technitium.com/dns/

APP="Technitium DNS"
var_tags="${var_tags:-dns}"
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
  if [[ ! -d /etc/dns ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if is_package_installed "aspnetcore-runtime-8.0"; then
    $STD apt remove -y aspnetcore-runtime-8.0
    $STD apt install -y aspnetcore-runtime-9.0
  fi

  RELEASE=$(curl -fsSL https://technitium.com/dns/ | grep -oP 'Version \K[\d.]+')
  if [[ ! -f ~/.technitium || "${RELEASE}" != "$(cat ~/.technitium)" ]]; then
    msg_info "Updating Technitium DNS"
    curl -fsSL "https://download.technitium.com/dns/DnsServerPortable.tar.gz" -o /opt/DnsServerPortable.tar.gz
    $STD tar zxvf /opt/DnsServerPortable.tar.gz -C /opt/technitium/dns/
    msg_ok "Updated Technitium DNS"

    msg_info "Cleaning up"
    rm -f /opt/DnsServerPortable.tar.gz
    msg_ok "Cleaned up"
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required.  Technitium DNS is already at v${RELEASE}."
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5380${CL}"
