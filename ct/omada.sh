#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.tp-link.com/us/support/download/omada-software-controller/

APP="Omada"
var_tags="tp-link;controller"
var_cpu="2"
var_ram="2048"
var_disk="8"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/tplink ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating MongoDB"
  MONGODB_VERSION="7.0"
  if ! lscpu | grep -q 'avx'; then
    MONGODB_VERSION="4.4"
    msg_error "No AVX detected: TP-Link Canceled Support for Old MongoDB for Debian 12\n https://www.tp-link.com/baltic/support/faq/4160/"
    exit 1 
  fi

  wget -qO- https://www.mongodb.org/static/pgp/server-${MONGODB_VERSION}.asc | gpg --dearmor >/usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg
  echo "deb [signed-by=/usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg] http://repo.mongodb.org/apt/debian $(grep '^VERSION_CODENAME=' /etc/os-release | cut -d'=' -f2)/mongodb-org/${MONGODB_VERSION} main" >/etc/apt/sources.list.d/mongodb-org-${MONGODB_VERSION}.list
  $STD apt-get update
  $STD apt-get install -y --only-upgrade mongodb-org
  msg_ok "Updated MongoDB to $MONGODB_VERSION"

  msg_info "Updating Omada Controller"
  latest_url=$(curl -s "https://support.omadanetworks.com/en/download/software/omada-controller/" | grep -o 'https://static\.tp-link\.com/upload/software/[^"]*linux_x64[^"]*\.deb' | head -n 1)
  latest_version=$(basename "$latest_url")
  if [ -z "${latest_version}" ]; then
    msg_error "It seems that the server (tp-link.com) might be down. Please try again at a later time."
    exit
  fi

  wget -qL ${latest_url}
  dpkg -i ${latest_version}
  rm -rf ${latest_version}
  msg_ok "Updated Omada Controller"
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:8043${CL}"
