#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/iv-org/invidious

APP="Invidious"
var_tags="${var_tags:-streaming}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
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

  if [[ ! -d /opt/invidious ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "Invidious" "iv-org/invidious"; then
    msg_info "Stopping services"
    $STD systemctl stop invidious-companion invidious
    msg_ok "Stopped services"

    create_backup /opt/invidious/config/config.yml

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Invidious" "iv-org/invidious" "tarball" "latest" "/opt/invidious"
    if check_for_gh_release "Invidious-Companion" "iv-org/invidious-companion"; then
      CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Invidious-Companion" "iv-org/invidious-companion" "prebuild" "latest" "/opt/invidious-companion" "invidious_companion-$(arch_resolve x86_64 aarch64)-unknown-linux-gnu.tar.gz"
    fi

    msg_info "Rebuilding Invidious"
    cd /opt/invidious
    INVIDIOUS_VERSION="$(cat ~/.invidious 2>/dev/null || echo "unknown")"
    INVIDIOUS_VERSION="${INVIDIOUS_VERSION#v}"
    sed -i \
      -e "s~^\(\s*CURRENT_BRANCH\s*=\).*~\1 \"master\"~" \
      -e "s~^\(\s*CURRENT_COMMIT\s*=\).*~\1 \"\"~" \
      -e "s~^\(\s*CURRENT_VERSION\s*=\).*~\1 \"${INVIDIOUS_VERSION}\"~" \
      -e "s~^\(\s*CURRENT_TAG\s*=\).*~\1 \"${INVIDIOUS_VERSION}\"~" \
      -e "s~^\(\s*ASSET_COMMIT\s*=\).*~\1 \"\"~" \
      src/invidious.cr
    $STD make
    msg_ok "Rebuilt Invidious"

    restore_backup

    msg_info "Starting services"
    $STD systemctl start invidious invidious-companion
    msg_ok "Started services"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
