#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/plastic-labs/honcho

APP="Honcho"
var_tags="${var_tags:-ai;memory;agents}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

export var_honcho_provider="${var_honcho_provider:-}"
export var_honcho_api_key="${var_honcho_api_key:-}"
export var_honcho_base_url="${var_honcho_base_url:-}"
export var_honcho_model="${var_honcho_model:-}"
export var_honcho_embedding_key="${var_honcho_embedding_key:-}"
export var_honcho_embedding_model="${var_honcho_embedding_model:-}"
export var_honcho_embedding_dims="${var_honcho_embedding_dims:-}"

header_info "$APP"
variables
color
catch_errors

if [[ -n "${var_honcho_provider}" && ! "${var_honcho_provider}" =~ ^(openai|anthropic|gemini)$ ]]; then
  msg_error "var_honcho_provider must be openai, anthropic or gemini"
  exit 1
fi

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/honcho ]]; then
    msg_error "No Honcho Installation Found!"
    exit
  fi

  if check_for_gh_release "honcho" "plastic-labs/honcho" "" "" "v"; then
    msg_info "Stopping Honcho"
    systemctl stop honcho-deriver honcho
    msg_ok "Stopped Honcho"

    PYTHON_VERSION="3.13" setup_uv
    CLEAN_INSTALL=1 CLEAN_INSTALL_KEEP=".env" fetch_and_deploy_gh_release "honcho" "plastic-labs/honcho" "tarball" "latest" "/opt/honcho" "" "v"

    msg_info "Updating Honcho"
    cd /opt/honcho
    $STD uv sync --frozen --no-dev
    $STD .venv/bin/python scripts/provision_db.py
    msg_ok "Updated Honcho"

    if systemctl is-enabled -q honcho; then
      msg_info "Starting Honcho"
      systemctl start honcho honcho-deriver
      msg_ok "Started Honcho"
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
echo -e "${INFO}${YW}Access the API (interactive docs at /docs) using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8000${CL}"
echo -e "${INFO}${YW}Admin key, sent as Authorization: Bearer <key> (more with: cd /opt/honcho && .venv/bin/python scripts/generate_jwt.py --admin):${CL}"
echo -e "${INFO}${YW}Without an LLM provider key Honcho stays stopped: set one in /opt/honcho_data/.env, then run: systemctl enable --now honcho honcho-deriver${CL}"
