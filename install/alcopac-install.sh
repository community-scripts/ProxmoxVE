#!/usr/bin/env bash
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://dev.alcopa.cc/

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Base Dependencies"
# Ставимо лише базові утиліти для контейнера. 
# ffmpeg, nodejs та інші залежності Alcopac встановить сам.
$STD apt-get install -y curl sudo mc wget unzip
msg_ok "Installed Base Dependencies"

msg_info "Installing Alcopac (Non-interactive)"
# Використовуємо пряму команду для тихого встановлення
$STD bash -c "curl -fsSL https://dev.alcopa.cc/install | bash -s install"
msg_ok "Installed Alcopac"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"