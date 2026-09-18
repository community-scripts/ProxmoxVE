#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/DioCrafts/OxiCloud

APP="OxiCloud"
var_tags="${var_tags:-files;documents}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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

  if [[ ! -d /opt/oxicloud ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "OxiCloud" "DioCrafts/OxiCloud"; then
    msg_info "Stopping OxiCloud"
    systemctl stop oxicloud
    msg_ok "Stopped OxiCloud"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "OxiCloud" "DioCrafts/OxiCloud" "prebuild" "latest" "/opt/oxicloud" "oxicloud-*-$(arch_resolve x86_64 aarch64)-unknown-linux-musl.tar.gz"

    msg_info "Updating OxiCloud"
    install -m 755 /opt/oxicloud/oxicloud /usr/local/bin/oxicloud
    rm -f /usr/local/bin/migrate-nfc-filenames /usr/bin/oxicloud
    sed -i 's|^OXICLOUD_STATIC_PATH=|#OXICLOUD_STATIC_PATH=|' /etc/oxicloud/.env
    msg_ok "Updated OxiCloud"

    msg_info "Starting OxiCloud"
    systemctl start oxicloud
    msg_ok "Started OxiCloud"
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
echo -e "${GATEWAY}${BGN}http://${IP}:8086${CL}"
