#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: tteck (tteckster) | MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.plex.tv/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Setting Up Plex Media Server Repository"
setup_deb822_repo \
  "plexmediaserver" \
  "https://downloads.plex.tv/plex-keys/PlexSign.v2.key" \
  "https://repo.plex.tv/deb/" \
  "public" \
  "main"
msg_ok "Set Up Plex Media Server Repository"

msg_info "Installing Plex Media Server"
$STD apt install -y plexmediaserver
msg_ok "Installed Plex Media Server"

setup_hwaccel "plex"

motd_ssh
customize
cleanup_lxc
