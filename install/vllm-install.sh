#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/vllm-project/vllm

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

var_backend="${var_backend:-auto}"
var_model="${var_model:-Qwen/Qwen2.5-0.5B-Instruct}"
var_port="${var_port:-8000}"
var_dtype="${var_dtype:-auto}"
var_vram_utilization="${var_vram_utilization:-0.90}"
var_max_model_len="${var_max_model_len:-}"
var_hf_token="${var_hf_token:-}"
var_api_key="${var_api_key:-}"

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  python3-dev
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.12" setup_uv
setup_hwaccel

if [[ "$var_backend" == "auto" ]]; then
  case "${HWACCEL_VENDOR:-none}" in
  nvidia) var_backend="cuda" ;;
  amd) var_backend="rocm" ;;
  *) var_backend="cpu" ;;
  esac
fi

VLLM_VERSION="$(get_latest_github_release "vllm-project/vllm")"

msg_info "Installing vLLM (${var_backend}, Patience)"
$STD uv venv --python 3.12 /opt/vllm
case "$var_backend" in
cuda)
  $STD uv pip install --python /opt/vllm/bin/python vllm
  ;;
rocm)
  $STD uv pip install --python /opt/vllm/bin/python vllm \
    --extra-index-url https://wheels.vllm.ai/rocm/ --upgrade
  ;;
cpu)
  if [[ "$(uname -m)" != "x86_64" ]]; then
    msg_error "vLLM publishes no prebuilt CPU wheel for $(uname -m)"
    exit 1
  fi
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
  msg_error "Unknown var_backend '${var_backend}' (expected auto, cuda, rocm or cpu)"
  exit 1
  ;;
esac
echo "$var_backend" >/opt/vllm/.backend
cat <<EOF >~/.vllm
${VLLM_VERSION}
EOF
msg_ok "Installed vLLM (${var_backend})"

msg_info "Configuring vLLM"
mkdir -p /opt/vllm/models
VLLM_SERVE_ARGS="--dtype ${var_dtype} --gpu-memory-utilization ${var_vram_utilization}"
[[ -n "$var_max_model_len" ]] && VLLM_SERVE_ARGS+=" --max-model-len ${var_max_model_len}"
cat <<EOF >/opt/vllm/vllm.env
VLLM_MODEL=${var_model}
VLLM_HOST=0.0.0.0
VLLM_PORT=${var_port}
HF_HOME=/opt/vllm/models
HF_TOKEN=${var_hf_token}
VLLM_API_KEY=${var_api_key}
# Appended to 'vllm serve' verbatim.
VLLM_SERVE_ARGS=${VLLM_SERVE_ARGS}
EOF

CUDA_ROOT="$(find /opt/vllm/lib/python3*/site-packages/nvidia -maxdepth 1 -type d -name 'cu[0-9]*' 2>/dev/null | sort -V | tail -1 || true)"
if [[ -n "$CUDA_ROOT" ]]; then
  CUDART="$(find "${CUDA_ROOT}/lib" -maxdepth 1 -name 'libcudart.so.*' 2>/dev/null | sort -V | tail -1 || true)"
  if [[ -n "$CUDART" && ! -e "${CUDA_ROOT}/lib/libcudart.so" ]]; then
    ln -s "$(basename "$CUDART")" "${CUDA_ROOT}/lib/libcudart.so"
  fi
  cat <<EOF >>/opt/vllm/vllm.env
CUDA_HOME=${CUDA_ROOT}
FLASHINFER_NVCC=${CUDA_ROOT}/bin/nvcc
PATH=${CUDA_ROOT}/bin:/opt/vllm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LD_LIBRARY_PATH=${CUDA_ROOT}/lib
LIBRARY_PATH=${CUDA_ROOT}/lib
EOF
fi
chmod 600 /opt/vllm/vllm.env
msg_ok "Configured vLLM"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/vllm.service
[Unit]
Description=vLLM OpenAI-Compatible Inference Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/vllm
EnvironmentFile=/opt/vllm/vllm.env
ExecStart=/opt/vllm/bin/vllm serve \${VLLM_MODEL} --host \${VLLM_HOST} --port \${VLLM_PORT} \$VLLM_SERVE_ARGS
Restart=on-failure
RestartSec=10
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now vllm
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
