#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/mkforde/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Mike F (mkforde)
# License: MIT | https://github.com/mkforde/ProxmoxVE/raw/main/LICENSE
# Source: https://seanime.app/ | Github: https://github.com/5rahim/seanime

APP="Seanime"
var_tags="${var_tags:-anime;manga}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_gpu="${var_gpu:-yes}"

header_info "$APP"
variables
color
catch_errors

function normalize_seanime_binary() {
  local binary_path
  binary_path=$(find /opt/seanime/app -maxdepth 1 -type f \( -name 'seanime' -o -name 'seanime-*' -o -name 'Seanime*' \) ! -name '*.tar.gz' ! -name '*.zip' | sort | head -n1)

  if [[ -z "$binary_path" ]]; then
    msg_error "Unable to locate Seanime binary after extraction"
    exit
  fi

  chmod 755 "$binary_path"
  if [[ "$binary_path" != "/opt/seanime/app/seanime" ]]; then
    mv "$binary_path" /opt/seanime/app/seanime
  fi
  chmod 755 /opt/seanime/app/seanime
  chown -R root:root /opt/seanime/app
}

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -x /opt/seanime/app/seanime ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "seanime" "5rahim/seanime"; then
    msg_info "Stopping Service"
    systemctl stop seanime
    msg_ok "Stopped Service"

    case "$(dpkg --print-architecture 2>/dev/null || uname -m)" in
    amd64 | x86_64)
      CLEAN_INSTALL=1 fetch_and_deploy_gh_release "seanime" "5rahim/seanime" "prebuild" "latest" "/opt/seanime/app" "seanime-*Linux_x86_64.tar.gz"
      ;;
    arm64 | aarch64)
      CLEAN_INSTALL=1 fetch_and_deploy_gh_release "seanime" "5rahim/seanime" "prebuild" "latest" "/opt/seanime/app" "seanime-*Linux_arm64.tar.gz"
      ;;
    *)
      msg_error "Unsupported architecture: $(dpkg --print-architecture 2>/dev/null || uname -m)"
      exit
      ;;
    esac
    normalize_seanime_binary

    msg_info "Starting Service"
    systemctl start seanime
    msg_ok "Started Service"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:43211${CL}"
