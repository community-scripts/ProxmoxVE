#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://sftpgo.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y sqlite3
msg_ok "Installed Dependencies"

setup_deb822_repo \
  "sftpgo" \
  "https://ftp.osuosl.org/pub/sftpgo/apt/gpg.key" \
  "https://ftp.osuosl.org/pub/sftpgo/apt" \
  "trixie"

msg_info "Installing SFTPGo"
$STD apt install -y sftpgo
msg_ok "Installed SFTPGo"

motd_ssh
customize
cleanup_lxc
