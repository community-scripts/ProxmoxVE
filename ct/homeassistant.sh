#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.home-assistant.io/

APP="Home Assistant"
var_tags="${var_tags:-automation;smarthome;docker}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-16}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /var/lib/docker/volumes/hass_config/_data ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  UPD=$(msg_menu "Home Assistant Update Options" \
    "1" "Update ALL Containers" \
    "2" "Remove ALL Unused Images" \
    "3" "Install HACS" \
    "4" "Install FileBrowser")

  if [ "$UPD" == "1" ]; then
    msg_info "Updating All Containers"
    CONTAINER_LIST="${1:-$(docker ps -q)}"
    for container in ${CONTAINER_LIST}; do
      CONTAINER_IMAGE="$(docker inspect --format "{{.Config.Image}}" --type container "${container}")"
      RUNNING_IMAGE="$(docker inspect --format "{{.Image}}" --type container "${container}")"
      docker pull "${CONTAINER_IMAGE}"
      LATEST_IMAGE="$(docker inspect --format "{{.Id}}" --type image "${CONTAINER_IMAGE}")"
      if [[ "${RUNNING_IMAGE}" != "${LATEST_IMAGE}" ]]; then
        pip install -U runlike --break-system-packages
        echo "Updating ${container} image ${CONTAINER_IMAGE}"
        DOCKER_COMMAND="$(runlike --use-volume-id "${container}")"
        docker rm --force "${container}"
        eval "${DOCKER_COMMAND}"
      fi
    done
    msg_ok "Updated All Containers"
    exit
  fi
  if [ "$UPD" == "2" ]; then
    msg_info "Removing ALL Unused Images"
    docker image prune -af
    msg_ok "Removed ALL Unused Images"
    exit
  fi
  if [ "$UPD" == "3" ]; then
    msg_info "Installing Home Assistant Community Store (HACS)"
    apt_update_safe
    cd /var/lib/docker/volumes/hass_config/_data
    $STD bash <(curl -fsSL https://get.hacs.xyz)
    msg_ok "Installed Home Assistant Community Store (HACS)"
    echo -e "\n Reboot Home Assistant and clear browser cache then Add HACS integration.\n"
    exit
  fi
  if [ "$UPD" == "4" ]; then
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/filebrowser.sh)"
    exit
  fi
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}HA: http://${IP}:8123${CL}"
echo -e "${GATEWAY}${BGN}Portainer: https://${IP}:9443${CL}"
