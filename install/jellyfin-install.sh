#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://jellyfin.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_custom "ℹ️" "${GN}" "If NVIDIA GPU passthrough is detected, you'll be asked whether to install drivers in the container"
setup_hwaccel "jellyfin"

msg_info "Installing Dependencies"
ensure_dependencies libjemalloc2
if [[ ! -f /usr/lib/libjemalloc.so ]]; then
  ln -sf /usr/lib/x86_64-linux-gnu/libjemalloc.so.2 /usr/lib/libjemalloc.so
fi
msg_ok "Installed Dependencies"

msg_info "Setting up Jellyfin Repository"
setup_deb822_repo \
  "jellyfin" \
  "https://repo.jellyfin.org/jellyfin_team.gpg.key" \
  "https://repo.jellyfin.org/$(get_os_info id)" \
  "$(get_os_info codename)"
msg_ok "Set up Jellyfin Repository"

msg_info "Installing Jellyfin"
$STD apt install -y jellyfin jellyfin-ffmpeg7
ln -sf /usr/lib/jellyfin-ffmpeg/ffmpeg /usr/bin/ffmpeg
ln -sf /usr/lib/jellyfin-ffmpeg/ffprobe /usr/bin/ffprobe
msg_ok "Installed Jellyfin"

msg_info "Configuring Jellyfin"
# Configure log rotation to prevent disk fill (keeps fail2ban compatibility) (PR: #1690 / Issue: #11224)
cat <<EOF >/etc/logrotate.d/jellyfin
/var/log/jellyfin/*.log {
    daily
    rotate 3
    maxsize 100M
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
}
EOF
chown -R jellyfin:adm /etc/jellyfin
sleep 10
systemctl restart jellyfin
msg_ok "Configured Jellyfin"

motd_ssh
customize
cleanup_lxc
