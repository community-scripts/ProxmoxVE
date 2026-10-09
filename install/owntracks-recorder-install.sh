#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/owntracks/recorder

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y mosquitto
systemctl enable -q --now mosquitto
msg_ok "Installed Dependencies"

setup_deb822_repo \
  "owntracks" \
  "https://raw.githubusercontent.com/owntracks/recorder/master/etc/repo-v2.owntracks.org.gpg.key" \
  "http://repo.owntracks.org/debian" \
  "$(get_os_info codename)" \
  "main"

msg_info "Installing OwnTracks Recorder"
$STD apt install -y ot-recorder
msg_ok "Installed OwnTracks Recorder"

msg_info "Configuring OwnTracks Recorder"
cat <<EOF >/etc/default/ot-recorder
OTR_HOST=127.0.0.1
OTR_PORT=1883
OTR_STORAGEDIR=/opt/owntracks_data
OTR_HTTPHOST=0.0.0.0
OTR_HTTPPORT=8083
EOF
mkdir -p /opt/owntracks_data
chown -R owntracks:owntracks /opt/owntracks_data 2>/dev/null || true
systemctl enable -q --now ot-recorder
msg_ok "Configured OwnTracks Recorder"

motd_ssh
customize
cleanup_lxc
