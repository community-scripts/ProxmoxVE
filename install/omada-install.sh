#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl sudo mc gnupg jsvc
msg_ok "Installed Dependencies"

msg_info "Checking CPU Features"
if lscpu | grep -q 'avx'; then
    USE_AVX=true
    msg_ok "AVX detected: Using MongoDB 8.0"
else
    USE_AVX=false
    msg_ok "No AVX detected: Using MongoDB 4.4"
fi

msg_info "Installing Azul Zulu"
wget -qO /etc/apt/trusted.gpg.d/zulu-repo.asc "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xB1998361219BD9C9"
wget -q https://cdn.azul.com/zulu/bin/zulu-repo_1.0.0-3_all.deb
$STD dpkg -i zulu-repo_1.0.0-3_all.deb
$STD apt-get update
$STD apt-get -y install zulu8-jdk
msg_ok "Installed Azul Zulu"

msg_info "Installing MongoDB"
if [[ "$USE_AVX" == true ]]; then
    wget -qL https://repo.mongodb.org/apt/debian/dists/bookworm/mongodb-org/8.0/main/binary-amd64/mongodb-org-server_8.0.4_amd64.deb
    $STD dpkg -i mongodb-org-server_8.0.4_amd64.deb
else
    wget -qL https://repo.mongodb.org/apt/debian/dists/buster/mongodb-org/4.4/main/binary-amd64/mongodb-org-server_4.4.29_amd64.deb
    $STD dpkg -i mongodb-org-server_4.4.29_amd64.deb
fi
msg_ok "Installed MongoDB"

msg_info "Installing Omada Controller"
latest_url=$(curl -s "https://support.omadanetworks.com/en/product/omada-software-controller/?resourceType=download" | grep -o 'https://static\.tp-link\.com/upload/software/[^"]*linux_x64[^"]*\.deb' | head -n 1)
latest_version=$(basename "$latest_url")

wget -qL ${latest_url}
$STD dpkg -i ${latest_version}
msg_ok "Installed Omada Controller"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf ${latest_version} mongodb-org-server_* zulu-repo_1.0.0-3_all.deb
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
