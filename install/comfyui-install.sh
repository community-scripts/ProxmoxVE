#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: jdacode
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/comfyanonymous/ComfyUI

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os
setup_hwaccel

echo
echo "${TAB3}Choose the GPU type for ComfyUI:"
echo "${TAB3}[1]-None  [2]-NVIDIA  [3]-AMD  [4]-Intel"
read -rp "${TAB3}Enter your choice [1-4] (default: 1): " gpu_choice
gpu_choice=${gpu_choice:-1}
case "$gpu_choice" in
1) comfyui_gpu_type="none" ;;
2) comfyui_gpu_type="nvidia" ;;
3) comfyui_gpu_type="amd" ;;
4) comfyui_gpu_type="intel" ;;
*)
  comfyui_gpu_type="none"
  echo "${TAB3}Invalid choice. Defaulting to ${comfyui_gpu_type}."
  ;;
esac
echo

PYTHON_VERSION="3.12" setup_uv

fetch_and_deploy_gh_release "ComfyUI" "comfyanonymous/ComfyUI" "tarball" "latest" "/opt/ComfyUI"

msg_info "Python dependencies"

# Extract PyTorch installation URLs from ComfyUI README for latest versions
# Fallback to hardcoded values if extraction fails
pytorch_nvidia_url="https://download.pytorch.org/whl/cu130"
pytorch_amd_url="https://download.pytorch.org/whl/rocm6.4"
pytorch_intel_url="https://download.pytorch.org/whl/xpu"

if [[ -f "/opt/ComfyUI/README.md" ]]; then
  # Extract NVIDIA CUDA URL (looking for stable, not nightly)
  nvidia_url=$(grep -oP 'pip install.*?--extra-index-url\s+\Khttps://download\.pytorch\.org/whl/cu\d+' /opt/ComfyUI/README.md | head -1 || true)
  [[ -n "$nvidia_url" ]] && pytorch_nvidia_url="$nvidia_url"
  
  # Extract AMD ROCm URL (stable version, not nightly)
  amd_url=$(grep -oP 'pip install.*?--index-url\s+\Khttps://download\.pytorch\.org/whl/rocm[\d.]+' /opt/ComfyUI/README.md | grep -v 'nightly' | head -1 || true)
  [[ -n "$amd_url" ]] && pytorch_amd_url="$amd_url"
  
  # Extract Intel XPU URL
  intel_url=$(grep -oP 'pip install.*?--index-url\s+\Khttps://download\.pytorch\.org/whl/xpu' /opt/ComfyUI/README.md | head -1 || true)
  [[ -n "$intel_url" ]] && pytorch_intel_url="$intel_url"
fi

$STD uv venv "/opt/ComfyUI/venv"
if [[ "${comfyui_gpu_type,,}" == "nvidia" ]]; then
  $STD uv pip install \
    torch \
    torchvision \
    torchaudio \
    --extra-index-url "$pytorch_nvidia_url" \
    --python="/opt/ComfyUI/venv/bin/python"
elif [[ "${comfyui_gpu_type,,}" == "amd" ]]; then
  $STD uv pip install \
    torch \
    torchvision \
    torchaudio \
    --index-url "$pytorch_amd_url" \
    --python="/opt/ComfyUI/venv/bin/python"
elif [[ "${comfyui_gpu_type,,}" == "intel" ]]; then
  $STD uv pip install \
    torch \
    torchvision \
    torchaudio \
    --index-url "$pytorch_intel_url" \
    --python="/opt/ComfyUI/venv/bin/python"
fi
$STD uv pip install -r "/opt/ComfyUI/requirements.txt" --python="/opt/ComfyUI/venv/bin/python"
msg_ok "Python dependencies"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/comfyui.service
[Unit]
Description=ComfyUI Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ComfyUI
ExecStart=/opt/ComfyUI/venv/bin/python /opt/ComfyUI/main.py --listen --port 8188
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now comfyui
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
