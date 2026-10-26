#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/EgalitarianMonkey/hometube

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_ffmpeg
PYTHON_VERSION="3.13" setup_uv
fetch_and_deploy_gh_release "deno" "denoland/deno" "prebuild" "latest" "/usr/local/bin" "deno-$(arch_resolve "x86_64" "aarch64")-unknown-linux-gnu.zip"
fetch_and_deploy_gh_release "yt-dlp" "yt-dlp/yt-dlp" "singlefile" "latest" "/usr/local/bin" "yt-dlp_$(arch_resolve "linux" "linux_aarch64")"
fetch_and_deploy_gh_release "hometube" "EgalitarianMonkey/hometube" "tarball"

msg_info "Installing HomeTube"
cd /opt/hometube
$STD uv sync --locked --no-dev --no-install-project --no-install-package pyarrow
mkdir -p /opt/hometube_data/{videos,tmp,cookies}
cat <<EOF >/opt/hometube_data/.env
VIDEOS_FOLDER=/opt/hometube_data/videos
TMP_DOWNLOAD_FOLDER=/opt/hometube_data/tmp
YOUTUBE_COOKIES_FILE_PATH=/opt/hometube_data/cookies/youtube_cookies.txt
REMOVE_TMP_FILES_AFTER_DOWNLOAD=true
EOF
msg_ok "Installed HomeTube"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/hometube.service
[Unit]
Description=HomeTube
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/hometube
EnvironmentFile=/opt/hometube_data/.env
Environment=PYTHONUNBUFFERED=1
ExecStartPre=-/usr/local/bin/yt-dlp -U
ExecStart=/opt/hometube/.venv/bin/python -m streamlit run app/main.py --server.port=8501 --server.address=0.0.0.0 --server.headless=true --server.enableCORS=false --server.enableXsrfProtection=false
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now hometube
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
