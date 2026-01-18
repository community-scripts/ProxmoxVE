#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.audiobookshelf.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y ffmpeg
msg_ok "Installed Dependencies"

setup_deb822_repo \
  "audiobookshelf" \
  "https://advplyr.github.io/audiobookshelf-ppa/KEY.gpg" \
  "https://advplyr.github.io/audiobookshelf-ppa" \
  "./"

msg_info "Setup audiobookshelf"
$STD apt install -y audiobookshelf
echo "FFMPEG_PATH=/usr/bin/ffmpeg" >>/etc/default/audiobookshelf
echo "FFPROBE_PATH=/usr/bin/ffprobe" >>/etc/default/audiobookshelf
systemctl restart audiobookshelf
msg_ok "Setup audiobookshelf"

motd_ssh
customize
cleanup_lxc
