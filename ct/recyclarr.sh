#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MrYadro
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://recyclarr.dev/wiki/ | Github: https://github.com/recyclarr/recyclarr

APP="Recyclarr"
var_tags="${var_tags:-arr}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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
  if [[ ! -f /root/.config/recyclarr/recyclarr.yml ]] && [[ ! -d /root/.config/recyclarr/configs ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "recyclarr" "recyclarr/recyclarr"; then

    msg_info "Updating ${APP}"

    fetch_and_deploy_gh_release "recyclarr" "recyclarr/recyclarr" "prebuild" "latest" "/usr/local/bin" "recyclarr-linux-x64.tar.xz"

    # Migrate includes from configs/ to includes/ (recyclarr v8)
    RECYCLARR_DIR="/root/.config/recyclarr"
    mkdir -p "$RECYCLARR_DIR/includes"
    if [[ -d "$RECYCLARR_DIR/configs" ]]; then
      for item in "$RECYCLARR_DIR/configs"/*/; do
        [[ -d "$item" ]] || continue
        dir_name=$(basename "$item")
        # Only move subdirs that look like include dirs (not the configs themselves)
        if [[ "$dir_name" != "configs" ]] && [[ ! -d "$RECYCLARR_DIR/includes/$dir_name" ]]; then
          mv "$item" "$RECYCLARR_DIR/includes/"
        fi
      done
    fi

    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following IP:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}${IP}${CL}"
