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
  if lscpu | grep -q 'avx'; then
    MONGO_VERSION="8.0" setup_mongodb
  else
    msg_warn "No AVX detected: Using older MongoDB 4.4"
    MONGO_VERSION="4.4" setup_mongodb
  fi

  msg_info "Checking if right Azul Zulu Java is installed"
  java_version=$(java -version 2>&1 | awk -F[\"_] '/version/ {print $2}')
  if [[ "$java_version" =~ ^1\.8\.* ]]; then
    $STD apt remove --purge -y zulu8-jdk
    $STD apt -y install zulu21-jre-headless
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
    exit
  fi
  curl -fsSL "$OMADA_URL" -o "$OMADA_PKG"
  export DEBIAN_FRONTEND=noninteractive
  $STD dpkg -i "$OMADA_PKG"
  rm -f "$OMADA_PKG"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:8043${CL}"
