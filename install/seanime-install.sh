#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: hasan-ismail
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://seanime.app/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_hwaccel

msg_info "Installing FFmpeg"
setup_deb822_repo \
  "jellyfin" \
  "https://repo.jellyfin.org/jellyfin_team.gpg.key" \
  "https://repo.jellyfin.org/debian" \
  "$(get_os_info codename)"
$STD apt install -y jellyfin-ffmpeg7
ln -sf /usr/lib/jellyfin-ffmpeg/ffmpeg /usr/bin/ffmpeg
ln -sf /usr/lib/jellyfin-ffmpeg/ffprobe /usr/bin/ffprobe
msg_ok "Installed FFmpeg"

fetch_and_deploy_gh_release "seanime" "5rahim/seanime" "prebuild" "latest" "/opt/seanime" "seanime-[0-9]*_Linux_$(arch_resolve x86_64 arm64).tar.gz"
chmod +x /opt/seanime/seanime

msg_info "Configuring Seanime"
SEANIME_PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
mkdir -p /opt/seanime-data
cat <<EOF >/opt/seanime-data/config.toml
[server]
password = "${SEANIME_PASSWORD}"
EOF
cat <<EOF >/root/seanime.creds
Seanime URL: http://${LOCAL_IP}:43211
Password: ${SEANIME_PASSWORD}
EOF
msg_ok "Configured Seanime"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/seanime.service
[Unit]
Description=Seanime
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/seanime
ExecStart=/opt/seanime/seanime --datadir /opt/seanime-data --host 0.0.0.0
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now seanime
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
