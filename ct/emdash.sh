#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/emdash-cms/emdash

APP="EmDash"
var_tags="${var_tags:-cms;blog}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-3072}"
var_disk="${var_disk:-6}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

export var_emdash_url="${var_emdash_url:-}"
export var_emdash_template="${var_emdash_template:-}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/emdash ]]; then
    msg_error "No EmDash Installation Found!"
    exit
  fi

  if check_for_gh_release "emdash" "emdash-cms/emdash" "" "" "emdash@"; then
    msg_info "Stopping EmDash"
    systemctl stop emdash
    msg_ok "Stopped EmDash"

    NODE_VERSION="24" NODE_MODULE="pnpm@11" setup_nodejs

    msg_info "Updating EmDash"
    cd /opt/emdash
    set -a && source /opt/emdash_data/.env && set +a
    $STD pnpm add "${CHECK_UPDATE_RELEASE}"
    $STD pnpm build
    $STD pnpm store prune
    cat <<EOF >~/.emdash
${CHECK_UPDATE_RELEASE}
EOF
    msg_ok "Updated EmDash"

    msg_info "Starting EmDash"
    systemctl start emdash
    msg_ok "Started EmDash"
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
echo -e "${GATEWAY}${BGN}http://${IP}:4321${CL}"
echo -e "${INFO}${YW}The admin at /_emdash/admin signs in with passkeys only, and browsers allow those on HTTPS with a domain or on localhost, never on an IP address.${CL}"
echo -e "${INFO}${YW}Put EmDash behind a reverse proxy with a trusted certificate, set EMDASH_SITE_URL in /opt/emdash_data/.env to that address and rebuild (see the notes), then create the admin there.${CL}"
