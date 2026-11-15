#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/vllm-project/vllm

APP="vLLM"
var_tags="${var_tags:-ai;llm;inference}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-20}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_gpu="${var_gpu:-yes}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/vllm ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  if check_for_gh_release "vllm" "vllm-project/vllm"; then
    msg_info "Stopping Service"
    systemctl stop vllm
    msg_ok "Stopped Service"

    create_backup /opt/vllm/vllm.env

    VLLM_BACKEND="$(cat /opt/vllm/.backend 2>/dev/null || echo cuda)"
    VLLM_VERSION="$(get_latest_github_release "vllm-project/vllm")"
    msg_info "Updating vLLM (${VLLM_BACKEND}, Patience)"
    case "$VLLM_BACKEND" in
    rocm)
      $STD uv pip install --python /opt/vllm/bin/python --upgrade vllm \
        --extra-index-url https://wheels.vllm.ai/rocm/
      ;;
    cpu)
      github_api_call "https://api.github.com/repos/vllm-project/vllm/releases/tags/v${VLLM_VERSION}" /tmp/vllm-release.json
      VLLM_WHEEL="$(jq -r '.assets[] | select(.name | endswith("+cpu-cp38-abi3-manylinux_2_39_x86_64.whl")) | .browser_download_url' /tmp/vllm-release.json | head -n1)"
      rm -f /tmp/vllm-release.json
      [[ -n "$VLLM_WHEEL" ]] || {
        msg_error "vLLM ${VLLM_VERSION} has no CPU wheel for x86_64"
        exit 1
      }
      $STD uv pip install --python /opt/vllm/bin/python "$VLLM_WHEEL" --torch-backend cpu
      ;;
    *)
      $STD uv pip install --python /opt/vllm/bin/python --upgrade vllm
      ;;
    esac
    msg_ok "Updated vLLM (${VLLM_BACKEND})"

    restore_backup

    msg_info "Refreshing CUDA Environment"
    CUDA_ROOT="$(find /opt/vllm/lib/python3*/site-packages/nvidia -maxdepth 1 -type d -name 'cu[0-9]*' 2>/dev/null | sort -V | tail -1 || true)"
    if [[ -n "$CUDA_ROOT" ]]; then
      CUDART="$(find "${CUDA_ROOT}/lib" -maxdepth 1 -name 'libcudart.so.*' 2>/dev/null | sort -V | tail -1 || true)"
      if [[ -n "$CUDART" && ! -e "${CUDA_ROOT}/lib/libcudart.so" ]]; then
        ln -s "$(basename "$CUDART")" "${CUDA_ROOT}/lib/libcudart.so"
      fi
      sed -i '/^\(CUDA_HOME\|FLASHINFER_NVCC\|PATH\|LD_LIBRARY_PATH\|LIBRARY_PATH\)=/d' /opt/vllm/vllm.env
      cat <<EOF >>/opt/vllm/vllm.env
CUDA_HOME=${CUDA_ROOT}
FLASHINFER_NVCC=${CUDA_ROOT}/bin/nvcc
PATH=${CUDA_ROOT}/bin:/opt/vllm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LD_LIBRARY_PATH=${CUDA_ROOT}/lib
LIBRARY_PATH=${CUDA_ROOT}/lib
EOF
    fi
    msg_ok "Refreshed CUDA Environment"

    msg_info "Starting Service"
    systemctl start vllm
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  cleanup_lxc
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000/v1${CL}"
