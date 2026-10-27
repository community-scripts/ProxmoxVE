#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bambanah/deemix

APP="Deemix"
var_tags="${var_tags:-music;downloader}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
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

  if [[ ! -d /opt/deemix ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # The monorepo releases every package under its own tag; the server is deemix-webui
  if check_for_gh_release "deemix" "bambanah/deemix" "" "" "deemix-webui@"; then
    msg_info "Stopping Deemix"
    systemctl stop deemix
    msg_ok "Stopped Deemix"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "deemix" "bambanah/deemix" "tarball" "latest" "/opt/deemix" "" "deemix-webui@"
    NODE_VERSION="24" NODE_MODULE="pnpm@$(sed -n 's/.*"packageManager": "pnpm@\([^"+]*\).*/\1/p' /opt/deemix/package.json)" setup_nodejs

    msg_info "Building Deemix"
    cd /opt/deemix
    ELECTRON_SKIP_BINARY_DOWNLOAD=1 $STD pnpm install --frozen-lockfile
    $STD pnpm turbo build --filter=deemix-webui...
    msg_ok "Built Deemix"

    msg_info "Starting Deemix"
    systemctl start deemix
    msg_ok "Started Deemix"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:6595${CL}"
