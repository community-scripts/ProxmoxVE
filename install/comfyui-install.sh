#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
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

echo
echo "${TAB3}Choose the GPU type for ComfyUI:"
echo "${TAB3}[1]-None  [2]-NVIDIA  [3]-AMD  [4]-Intel"
read -rp "${TAB3}Enter your choice [1-4] (default: 1): " gpu_choice
gpu_choice=${gpu_choice:-1}
case "$gpu_choice" in
1) comfyui_gpu_type="none";;
2) comfyui_gpu_type="nvidia";;
3) comfyui_gpu_type="amd";;
4) comfyui_gpu_type="intel";;
*) comfyui_gpu_type="none"; echo "${TAB3}Invalid choice. Defaulting to ${comfyui_gpu_type}." ;;
esac
echo

PYTHON_VERSION="3.12" setup_uv

fetch_and_deploy_gh_release "ComfyUI" "comfyanonymous/ComfyUI" "tarball" "latest" "/opt/ComfyUI"

msg_info "Python dependencies"
$STD uv venv "/opt/ComfyUI/venv"
if [[ "${comfyui_gpu_type,,}" == "nvidia" ]]; then
  $STD uv pip install \
      torch \
      torchvision \
      torchaudio \
      --extra-index-url "https://download.pytorch.org/whl/cu128" \
      --python="/opt/ComfyUI/venv/bin/python"
elif [[ "${comfyui_gpu_type,,}" == "amd" ]]; then
  $STD uv pip install \
      torch \
      torchvision \
      torchaudio \
      --index-url "https://download.pytorch.org/whl/rocm6.3" \
      --python="/opt/ComfyUI/venv/bin/python"
elif [[ "${comfyui_gpu_type,,}" == "intel" ]]; then
  $STD uv pip install \
      torch \
      torchvision \
      torchaudio \
      --index-url "https://download.pytorch.org/whl/xpu" \
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
ExecStart=/opt/ComfyUI/venv/bin/python /opt/ComfyUI/main.py --listen --port 8188 --cpu
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now comfyui
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
