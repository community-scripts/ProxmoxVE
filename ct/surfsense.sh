#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/MODSetter/SurfSense

APP="SurfSense"
var_tags="${var_tags:-ai;documents;rag}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-16}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}" # upstream stages llama.cpp and opencode for linux-x64 only
var_unprivileged="${var_unprivileged:-1}"

export var_surfsense_password="${var_surfsense_password:-}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/surfsense ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "surfsense" "MODSetter/SurfSense"; then
    msg_info "Stopping SurfSense"
    systemctl stop surfsense
    msg_ok "Stopped SurfSense"

    CLEAN_INSTALL=1 CLEAN_INSTALL_KEEP="surfsense_local/backend/.venv surfsense_local/backend/models" fetch_and_deploy_gh_release "surfsense" "MODSetter/SurfSense" "tarball"
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "caddy" "caddyserver/caddy" "prebuild" "v$(grep -oP 'CADDY_IMAGE=caddy:\K[0-9.]+' /opt/surfsense/docker/surfsense/Dockerfile)" "/opt/caddy" "caddy_*_linux_$(arch_resolve).tar.gz"
    NODE_VERSION="24" NODE_MODULE="$(jq -r '.packageManager' /opt/surfsense/surfsense_local/frontend/package.json)" setup_nodejs
    PYTHON_VERSION="3.12" setup_uv

    msg_info "Building SurfSense"
    cd /opt/surfsense/surfsense_local/frontend
    $STD pnpm install --frozen-lockfile
    VITE_API_BASE=/api VITE_SURFSENSE_RUNTIME=docker VITE_SURFSENSE_VERSION="$(cat ../VERSION)" $STD pnpm build
    rm -rf node_modules
    cd /opt/surfsense/surfsense_local/backend
    $STD uv sync --frozen --no-dev
    SURFSENSE_LOCAL_DATA_DIR=/opt/surfsense_data $STD .venv/bin/python scripts/fetch_embedding_model.py models
    SURFSENSE_LOCAL_DATA_DIR=/opt/surfsense_data $STD .venv/bin/python scripts/fetch_docling_models.py models
    SURFSENSE_LOCAL_DATA_DIR=/opt/surfsense_data $STD .venv/bin/python scripts/fetch_silero_vad.py models
    cd /opt/surfsense/surfsense_local
    $STD node runtimes/fetch-llamacpp.mjs --variant cpu --out electron/llamacpp
    $STD node runtimes/opencode/stage.mjs
    msg_ok "Built SurfSense"

    msg_info "Starting SurfSense"
    systemctl start surfsense
    msg_ok "Started SurfSense"
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
