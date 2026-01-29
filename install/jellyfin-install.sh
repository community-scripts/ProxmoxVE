#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
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
setup_hwaccel

msg_info "Installing Jellyfin"
VERSION="$(awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release)"
if ! dpkg -s libjemalloc2 >/dev/null 2>&1; then
  $STD apt install -y libjemalloc2
fi
if [[ ! -f /usr/lib/libjemalloc.so ]]; then
  ln -sf /usr/lib/x86_64-linux-gnu/libjemalloc.so.2 /usr/lib/libjemalloc.so
fi
if [[ ! -d /etc/apt/keyrings ]]; then
  mkdir -p /etc/apt/keyrings
fi
curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key | gpg --dearmor --yes --output /etc/apt/keyrings/jellyfin.gpg
cat <<EOF >/etc/apt/sources.list.d/jellyfin.sources
Types: deb
URIs: https://repo.jellyfin.org/${PCT_OSTYPE}
Suites: ${VERSION}
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/jellyfin.gpg
EOF

$STD apt update
$STD apt install -y jellyfin
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
if [[ "$CTTYPE" == "0" ]]; then
  sed -i -e 's/^ssl-cert:x:104:$/render:x:104:root,jellyfin/' -e 's/^render:x:108:root,jellyfin$/ssl-cert:x:108:/' /etc/group
else
  sed -i -e 's/^ssl-cert:x:104:$/render:x:104:jellyfin/' -e 's/^render:x:108:jellyfin$/ssl-cert:x:108:/' /etc/group
fi
msg_ok "Installed Jellyfin"

motd_ssh
customize
cleanup_lxc
