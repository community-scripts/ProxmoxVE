#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.photoprism.app/

APP="PhotoPrism"
var_tags="${var_tags:-media;photo}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-3072}"
var_disk="${var_disk:-8}"
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
  if [[ ! -d /opt/photoprism ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "photoprism" "photoprism/photoprism"; then
    msg_info "Stopping PhotoPrism"
    systemctl stop photoprism
    msg_ok "Stopped PhotoPrism"

    fetch_and_deploy_gh_release "photoprism" "photoprism/photoprism" "prebuild" "latest" "/opt/photoprism" "*linux-amd64.tar.gz"

    LIBHEIF_URL=$(curl -fsSL "https://dl.photoprism.app/dist/libheif/" | grep -oP "libheif-$(lsb_release -cs)-amd64-v[0-9\.]+\.tar\.gz" | sort -V | tail -n 1)
    if [[ "${LIBHEIF_URL}" != "$(cat ~/.photoprism_libheif 2>/dev/null)" ]] || [[ ! -f ~/.photoprism_libheif ]]; then
      msg_info "Updating PhotoPrism LibHeif"
      $STD apt-get install -y libvips42
      curl -fsSL "https://dl.photoprism.app/dist/libheif/$LIBHEIF_URL" -o /tmp/libheif.tar.gz
      tar -xzf /tmp/libheif.tar.gz -C /usr/local
      ldconfig
      echo "${LIBHEIF_URL}" >~/.photoprism_libheif
      msg_ok "Updated PhotoPrism LibHeif"
    fi

    msg_info "Starting PhotoPrism"
    systemctl start photoprism
    msg_ok "Started PhotoPrism"
    msg_ok "Update Successful"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:2342${CL}"
