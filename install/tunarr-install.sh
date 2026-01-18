#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: chrisbenincasa
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tunarr.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_hwaccel

fetch_and_deploy_gh_release "tunarr" "chrisbenincasa/tunarr" "prebuild" "latest" "/opt/tunarr" "*linux-x64.tar.gz"
cd /opt/tunarr
mv tunarr* tunarr
fetch_and_deploy_gh_release "ersatztv-ffmpeg" "ErsatzTV/ErsatzTV-ffmpeg" "prebuild" "latest" "/opt/ErsatzTV-ffmpeg" "*-linux64-gpl-7.1.tar.xz"

msg_info "Set ErsatzTV-ffmpeg links"
chmod +x /opt/ErsatzTV-ffmpeg/bin/*
ln -sf /opt/ErsatzTV-ffmpeg/bin/ffmpeg /usr/bin/ffmpeg
ln -sf /opt/ErsatzTV-ffmpeg/bin/ffplay /usr/bin/ffplay
ln -sf /opt/ErsatzTV-ffmpeg/bin/ffprobe /usr/bin/ffprobe
msg_ok "ffmpeg links set"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/tunarr.service
[Unit]
Description=Tunarr Service
After=multi-user.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/tunarr
ExecStart=/opt/tunarr/tunarr
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now tunarr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
