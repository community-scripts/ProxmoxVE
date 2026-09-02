#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/teslamate-org/teslamate

APP="TeslaMate"
var_tags="${var_tags:-car;monitoring}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-16}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-no}" # unset = ask the user; set yes/no only when verified
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/teslamate ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "teslamate" "teslamate-org/teslamate"; then
    msg_info "Stopping Service"
    systemctl stop teslamate
    msg_ok "Stopped Service"

    if [[ ! -d /opt/elixir ]]; then
      msg_info "Migrating to newer Elixir (required by TeslaMate)"
      $STD apt remove -y elixir
      fetch_and_deploy_gh_release "elixir" "elixir-lang/elixir" "prebuild" "latest" "/opt/elixir" "elixir-otp-27.zip"
      for bin in elixir elixirc iex mix; do
        ln -sf "/opt/elixir/bin/$bin" "/usr/local/bin/$bin"
      done
      msg_ok "Migrated to newer Elixir"
    fi

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "teslamate" "teslamate-org/teslamate" "tarball"

    msg_info "Building TeslaMate (Patience)"
    cd /opt/teslamate
    export MIX_ENV=prod
    $STD mix local.hex --force
    $STD mix local.rebar --force
    $STD mix deps.get --only prod
    $STD npm install --prefix ./assets
    $STD npm run deploy --prefix ./assets
    $STD mix do phx.digest, release --overwrite
    msg_ok "Built TeslaMate"

    msg_info "Starting Service"
    systemctl start teslamate
    systemctl restart grafana-server
    msg_ok "Started Service"
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
echo -e "${GATEWAY}${BGN}http://${IP}:4000${CL}"
echo -e "${INFO}${YW}Grafana dashboards (admin/admin):${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
