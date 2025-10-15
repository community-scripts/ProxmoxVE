#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
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

setup_go

msg_info "Installing SFTPGo"
curl -fsSL https://ftp.osuosl.org/pub/sftpgo/apt/gpg.key | gpg --dearmor -o /usr/share/keyrings/sftpgo-archive-keyring.gpg
cat <<EOF >/etc/apt/sources.list.d/sftpgo.sources
Types: deb
URIs: https://ftp.osuosl.org/pub/sftpgo/apt
Suites: bookworm
Components: main
Signed-By: /usr/share/keyrings/sftpgo-archive-keyring.gpg
EOF
$STD apt update
$STD apt install -y sftpgo
msg_ok "Installed SFTPGo"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
