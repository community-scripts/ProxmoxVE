#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/norish-recipes/norish

APP="Norish"
var_tags="${var_tags:-recipes;meal-planning}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-12}"
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

  if [[ ! -d /opt/norish ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "norish" "norish-recipes/norish"; then
    msg_info "Stopping Norish"
    systemctl stop norish obscura
    msg_ok "Stopped Norish"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "norish" "norish-recipes/norish" "tarball"
    NODE_VERSION="22" NODE_MODULE="pnpm@$(jq -r '.packageManager | split("@")[1]' /opt/norish/package.json)" setup_nodejs
    PYTHON_VERSION="3.14" setup_uv
    fetch_and_deploy_gh_release "obscura" "h4ckf0r0day/obscura" "prebuild" "v$(sed -n 's/^OBSCURA_VERSION=//p' /opt/norish/docker/obscura/pin.env)" "/opt/obscura" "obscura-$(arch_resolve "x86_64" "aarch64")-linux-stealth.tar.gz"
    fetch_and_deploy_gh_release "yt-dlp" "yt-dlp/yt-dlp" "singlefile" "latest" "/usr/local/bin" "$(arch_resolve "yt-dlp_linux" "yt-dlp_linux_aarch64")"

    msg_info "Building Norish"
    cd /opt/norish
    $STD pnpm install --frozen-lockfile --filter "@norish/web..." --filter norish
    $STD uv sync --project /opt/norish/apps/parser-api --locked
    NODE_ENV=production SKIP_ENV_VALIDATION=1 NEXT_TELEMETRY_DISABLED=1 $STD pnpm turbo run build --filter "@norish/web"
    rm -rf /opt/norish/apps/web/.next/cache /opt/norish/apps/web/.next/standalone
    msg_ok "Built Norish"

    msg_info "Starting Norish"
    systemctl start obscura norish
    msg_ok "Started Norish"
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
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
