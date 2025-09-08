#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.tp-link.com/us/support/download/omada-software-controller/

APP="Omada"
var_tags="${var_tags:-tp-link;controller}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-3072}"
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

  curl -fsSL "https://www.mongodb.org/static/pgp/server-${MONGODB_VERSION}.asc" | gpg --dearmor >/usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg
  echo "deb [signed-by=/usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg] http://repo.mongodb.org/apt/debian $(grep '^VERSION_CODENAME=' /etc/os-release | cut -d'=' -f2)/mongodb-org/${MONGODB_VERSION} main" >/etc/apt/sources.list.d/mongodb-org-${MONGODB_VERSION}.list
  $STD apt-get update
  $STD apt-get install -y --only-upgrade mongodb-org
  msg_ok "Updated MongoDB to $MONGODB_VERSION"

  msg_info "Checking if right Azul Zulu Java is installed"
  java_version=$(java -version 2>&1 | awk -F[\"_] '/version/ {print $2}')
  if [[ "$java_version" =~ ^1\.8\.* ]]; then
    $STD apt-get remove --purge -y zulu8-jdk
    $STD apt-get -y install zulu21-jre-headless
    msg_ok "Updated Azul Zulu Java to 21"
  else
    msg_ok "Azul Zulu Java 21 already installed"
  fi

  msg_info "Updating Omada Controller"
  OMADA_URL=$(curl -fsSL "https://support.omadanetworks.com/en/download/software/omada-controller/" |
    grep -o 'https://static\.tp-link\.com/upload/software/[^"]*linux_x64[^"]*\.deb' |
    head -n1)
  OMADA_PKG=$(basename "$OMADA_URL")
  if [ -z "$OMADA_PKG" ]; then
    msg_error "Could not retrieve Omada package – server may be down."
    exit 1
  fi
  curl -fsSL "$OMADA_URL" -o "$OMADA_PKG"
  export DEBIAN_FRONTEND=noninteractive
  $STD dpkg -i "$OMADA_PKG"
  rm -f "$OMADA_PKG"
  msg_ok "Updated Omada Controller"
  exit 0
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:8043${CL}"
