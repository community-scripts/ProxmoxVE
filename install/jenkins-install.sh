#!/usr/bin/env bash
# Copyright (c) 2021-2025 community-scripts ORG
# Author: kristocopani
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.jenkins.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

JAVA_VERSION="21" setup_java

msg_info "Setup Jenkins"
curl -fsSL "https://pkg.jenkins.io/debian/jenkins.io-2023.key" -o "/usr/share/keyrings/jenkins-keyring.asc"
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" https://pkg.jenkins.io/debian binary/ >/etc/apt/sources.list.d/jenkins.list
$STD apt update
$STD apt install -y jenkins
msg_ok "Setup Jenkins"

motd_ssh
customize
cleanup_lxc
