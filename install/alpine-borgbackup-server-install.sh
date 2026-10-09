#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Sander Koenders (sanderkoenders)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.borgbackup.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing BorgBackup"
$STD apk add --no-cache borgbackup openssh
$STD rc-update add sshd
$STD rc-service sshd start
msg_ok "Installed BorgBackup"

msg_info "Creating backup user"
$STD adduser -D -s /bin/bash -h /home/backup backup
$STD passwd -d backup
msg_ok "Created backup user"

msg_info "Configure SSH, disabling password authentication and enabling public key authentication"
$STD sed -i -e 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
$STD rc-service sshd restart
msg_ok "Configured SSH"

motd_ssh
customize
cleanup_lxc
