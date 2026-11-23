#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/usesend/useSend

APP="useSend"
var_tags="${var_tags:-email;smtp;newsletter}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

export var_github_id="${var_github_id:-}"
export var_github_secret="${var_github_secret:-}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/usesend ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "usesend" "usesend/useSend"; then
    msg_info "Stopping useSend"
    systemctl stop usesend usesend-smtp
    msg_ok "Stopped useSend"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "usesend" "usesend/useSend" "tarball"
    NODE_VERSION="22" NODE_MODULE="pnpm@$(jq -r '.packageManager | split("@")[1]' /opt/usesend/package.json)" setup_nodejs

    msg_info "Building useSend"
    cd /opt/usesend
    PUPPETEER_SKIP_DOWNLOAD=true $STD pnpm install --frozen-lockfile --filter "web..." --filter smtp-server
    $STD pnpm --filter web db:generate
    SKIP_ENV_VALIDATION=true DOCKER_OUTPUT=1 NEXT_TELEMETRY_DISABLED=1 NEXT_PUBLIC_APP_VERSION="v$(cat ~/.usesend)" $STD pnpm --filter "web..." --filter smtp-server build
    cp -r apps/web/.next/static apps/web/.next/standalone/apps/web/.next/
    cp -r apps/web/public apps/web/.next/standalone/apps/web/
    rm -rf apps/web/.next/cache
    msg_ok "Built useSend"

    msg_info "Migrating useSend Database"
    set -a && source /opt/usesend_data/.env && set +a
    $STD pnpm --filter web db:migrate-deploy
    msg_ok "Migrated useSend Database"

    msg_info "Starting useSend"
    systemctl start usesend usesend-smtp
    msg_ok "Started useSend"
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
echo -e "${INFO}${YW}Login needs a GitHub OAuth app with the callback URL http://${IP}:3000/api/auth/callback/github${CL}"
echo -e "${INFO}${YW}If you skipped it, set GITHUB_ID/GITHUB_SECRET in /opt/usesend_data/.env, then run: systemctl enable --now usesend usesend-smtp${CL}"
