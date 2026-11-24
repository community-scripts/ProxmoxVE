#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/activepieces/activepieces

APP="Activepieces"
var_tags="${var_tags:-automation;workflow;ai}"
var_cpu="${var_cpu:-4}"
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

  if [[ ! -d /opt/activepieces ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "activepieces" "activepieces/activepieces"; then
    msg_info "Stopping Activepieces"
    systemctl stop activepieces activepieces-worker
    msg_ok "Stopped Activepieces"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "activepieces" "activepieces/activepieces" "tarball"
    NODE_VERSION="24" NODE_MODULE="$(jq -r '.packageManager' /opt/activepieces/package.json)" setup_nodejs
    fetch_and_deploy_gh_release "deno" "denoland/deno" "prebuild" "v$(jq -r '.devDependencies.deno' /opt/activepieces/packages/server/engine/package.json)" "/usr/local/bin" "deno-$(arch_resolve "x86_64" "aarch64")-unknown-linux-gnu.zip"

    msg_info "Building Activepieces"
    cd /opt/activepieces
    REDISMS_DISABLE_POSTINSTALL=1 $STD bun install --frozen-lockfile
    $STD npx turbo run build --filter=web --filter=@activepieces/engine --filter=api --filter=worker
    find dist/packages/web -name '*.map' -delete
    rm -rf node_modules bun.lock packages/pieces/core packages/pieces/custom packages/web packages/cli packages/tests-e2e packages/ee
    find packages/pieces/community -mindepth 1 -maxdepth 1 -type d ! -name slack ! -name square ! -name facebook-leads ! -name intercom ! -name microsoft-teams-bot -exec rm -rf {} +
    node -e "const fs=require('fs');const p=JSON.parse(fs.readFileSync('package.json','utf8'));p.workspaces=p.workspaces.filter(w=>fs.existsSync(w.replace('/*','')));fs.writeFileSync('package.json',JSON.stringify(p,null,2))"
    REDISMS_DISABLE_POSTINSTALL=1 $STD bun install --production
    rm -rf ~/.bun/install/cache
    msg_ok "Built Activepieces"

    msg_info "Starting Activepieces"
    systemctl start activepieces activepieces-worker
    msg_ok "Started Activepieces"
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
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
