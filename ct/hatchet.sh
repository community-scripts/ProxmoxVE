#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/hatchet-dev/hatchet

APP="Hatchet"
var_tags="${var_tags:-workflow;queue;automation}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-no}" # unset = ask the user; set yes/no only when verified
var_unprivileged="${var_unprivileged:-1}"

export var_admin_email="${var_admin_email:-}"
export var_admin_pass="${var_admin_pass:-}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/hatchet ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "hatchet" "hatchet-dev/hatchet"; then
    msg_info "Stopping Hatchet"
    systemctl stop hatchet
    msg_ok "Stopped Hatchet"

    setup_go
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "hatchet" "hatchet-dev/hatchet" "tarball"
    NODE_VERSION="24" NODE_MODULE="$(jq -r '.packageManager' /opt/hatchet/frontend/app/package.json)" setup_nodejs

    msg_info "Building Hatchet"
    cd /opt/hatchet/frontend/snippets
    $STD python3 generate.py
    cd /opt/hatchet/frontend/app
    $STD pnpm install --frozen-lockfile
    $STD pnpm run build
    cd /opt/hatchet
    for target in lite admin migrate; do
      CGO_ENABLED=0 $STD go build -ldflags="-w -s -X main.Version=v$(cat ~/.hatchet)" -o "bin/hatchet-${target}" "./cmd/hatchet-${target}"
    done
    rm -rf /opt/hatchet/frontend/app/node_modules ~/.local/share/pnpm/store
    $STD go clean -cache -modcache
    msg_ok "Built Hatchet"

    msg_info "Starting Hatchet"
    systemctl start hatchet
    msg_ok "Started Hatchet"
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
echo -e "${GATEWAY}${BGN}http://${IP}:8888${CL}"
echo -e "${INFO}${YW}Admin login: /opt/hatchet_data/.env (inside the container)${CL}"
