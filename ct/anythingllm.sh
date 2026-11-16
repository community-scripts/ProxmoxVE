#!/usr/bin/env bash
# Engine comes from community-scripts/core; this repo only ships the scripts.
# A local core checkout wins (COMMUNITY_SCRIPTS_CORE_DIR, else a sibling ../core),
# so a fork or branch of core can be tested without editing this file.
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Mintplex-Labs/anything-llm

APP="AnythingLLM"
var_tags="${var_tags:-ai;rag}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-20}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_gpu="${var_gpu:-yes}"
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

  if [[ ! -d /opt/anythingllm ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "anythingllm" "Mintplex-Labs/anything-llm"; then
    msg_info "Stopping Services"
    systemctl stop anythingllm anythingllm-collector
    msg_ok "Stopped Services"

    create_backup /opt/anythingllm/server/.env /opt/anythingllm/collector/.env /opt/anythingllm/frontend/.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "anythingllm" "Mintplex-Labs/anything-llm" "tarball"

    restore_backup

    msg_info "Building AnythingLLM (Patience)"
    cd /opt/anythingllm
    export PUPPETEER_SKIP_DOWNLOAD=true
    export NODE_OPTIONS="--max-old-space-size=3072"
    $STD yarn setup
    cd /opt/anythingllm/frontend
    $STD yarn build
    rm -rf /opt/anythingllm/server/public
    cp -R /opt/anythingllm/frontend/dist /opt/anythingllm/server/public
    cd /opt/anythingllm/server
    $STD npx prisma generate --schema=./prisma/schema.prisma
    $STD npx prisma migrate deploy --schema=./prisma/schema.prisma
    msg_ok "Built AnythingLLM"

    msg_info "Starting Services"
    systemctl start anythingllm anythingllm-collector
    msg_ok "Started Services"
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
echo -e "${GATEWAY}${BGN}http://${IP}:3001${CL}"
