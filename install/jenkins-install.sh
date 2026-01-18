#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
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
setup_deb822_repo \
  "jenkins" \
  "https://pkg.jenkins.io/debian/jenkins.io-2026.key" \
  "https://pkg.jenkins.io/debian" \
  "binary/" \
  " "

msg_info "Setup Jenkins"
$STD apt install -y jenkins
msg_ok "Setup Jenkins"

motd_ssh
customize
cleanup_lxc
