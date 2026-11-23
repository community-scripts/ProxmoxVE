#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: nnsense
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/TheBadFella/Pinchflat-NGX

APP="Pinchflat"
var_tags="${var_tags:-media;youtube;downloader}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_gpu="${var_gpu:-yes}"
var_arm64="${var_arm64:-yes}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/pinchflat/app ]]; then
    msg_error "No ${APP} installation found."
    exit 1
  fi

  if check_for_gh_release "pinchflat" "TheBadFella/Pinchflat-NGX"; then
    NODE_VERSION="24" NODE_MODULE="yarn" setup_nodejs

    msg_info "Stopping Service"
    systemctl stop pinchflat
    msg_ok "Stopped Service"

    if [[ ! -f /opt/pinchflat-src/lib/pinchflat/legacy_migration.ex && ! -f /opt/pinchflat-pre-ngx.tar.gz ]]; then
      NGX_SWITCH=1
      msg_info "Backing up Pinchflat before the switch to Pinchflat-NGX"
      tar -czf /opt/pinchflat-pre-ngx.tar.gz.part -C /opt/pinchflat --exclude=config/metadata --exclude=config/logs .env app config
      mv /opt/pinchflat-pre-ngx.tar.gz.part /opt/pinchflat-pre-ngx.tar.gz
      msg_ok "Backed up to /opt/pinchflat-pre-ngx.tar.gz"
    fi

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "pinchflat" "TheBadFella/Pinchflat-NGX" "tarball" "latest" "/opt/pinchflat-src"

    msg_info "Building Pinchflat-NGX"
    cd /opt/pinchflat-src
    export MIX_ENV=prod
    export ERL_FLAGS="+JPperf true"
    $STD mix local.hex --force
    $STD mix local.rebar --force
    $STD mix deps.get --only prod
    $STD mix deps.compile
    $STD yarn --cwd assets install
    $STD mix assets.deploy
    $STD mix compile
    $STD mix release --overwrite
    rm -rf /opt/pinchflat/app
    cp -r _build/prod/rel/pinchflat /opt/pinchflat/app
    msg_ok "Built Pinchflat-NGX"

    msg_info "Migrating Database"
    $STD systemd-run --wait --pipe --quiet --collect -p EnvironmentFile=/opt/pinchflat/.env -p WorkingDirectory=/opt/pinchflat/app /opt/pinchflat/app/bin/migrate
    msg_ok "Migrated Database"

    msg_info "Starting Service"
    systemctl start pinchflat
    msg_ok "Started Service"
    if [[ -n "${NGX_SWITCH:-}" ]]; then
      msg_warn "Open the web UI and confirm the migration review, downloads stay on hold until then"
    fi
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
echo -e "${GATEWAY}${BGN}http://${IP}:8945${CL}"
