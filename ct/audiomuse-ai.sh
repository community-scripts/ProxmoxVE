#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/NeptuneHub/AudioMuse-AI

APP="AudioMuse-AI"
var_tags="${var_tags:-music;ai}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-20}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/audiomuse-ai ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "audiomuse-ai" "NeptuneHub/AudioMuse-AI"; then
    msg_info "Stopping Services"
    systemctl stop audiomuse-ai audiomuse-ai-worker audiomuse-ai-worker-high audiomuse-ai-janitor audiomuse-ai-control
    msg_ok "Stopped Services"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "audiomuse-ai" "NeptuneHub/AudioMuse-AI" "tarball"

    AUDIOMUSE_BACKEND="$(cat /opt/audiomuse-ai_data/.backend 2>/dev/null || echo cpu)"
    REQ_COMMON="common.txt"
    case "$AUDIOMUSE_BACKEND" in
    gpu)
      REQ_ACCEL="gpu.txt"
      [[ "$(uname -m)" == "aarch64" ]] && REQ_ACCEL="gpu-arm64.txt"
      ;;
    cpu-noavx2)
      REQ_COMMON="common-noavx2.txt"
      REQ_ACCEL="cpu-noavx2.txt"
      ;;
    *)
      REQ_ACCEL="cpu.txt"
      ;;
    esac

    msg_info "Updating Python Environment (${AUDIOMUSE_BACKEND})"
    cd /opt/audiomuse-ai
    $STD uv venv --seed --python 3.12 /opt/audiomuse-ai/.venv
    $STD uv pip install --python /opt/audiomuse-ai/.venv \
      -r "/opt/audiomuse-ai/requirements/${REQ_COMMON}" \
      -r "/opt/audiomuse-ai/requirements/${REQ_ACCEL}"
    msg_ok "Updated Python Environment (${AUDIOMUSE_BACKEND})"

    msg_info "Starting Services"
    systemctl start audiomuse-ai audiomuse-ai-worker audiomuse-ai-worker-high audiomuse-ai-janitor audiomuse-ai-control
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
echo -e "${GATEWAY}${BGN}http://${IP}:8000${CL}"
