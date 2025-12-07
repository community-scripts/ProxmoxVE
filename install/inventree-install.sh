#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/inventree/InvenTree

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Setting up InvenTree Repository"
setup_deb822_repo \
  "inventree" \
  "https://dl.packager.io/srv/inventree/InvenTree/key" \
  "https://dl.packager.io/srv/deb/inventree/InvenTree/stable/$(get_os_info id)" \
  "$(get_os_info version)" \
  "main"
msg_ok "Set up InvenTree Repository"

msg_info "Installing InvenTree (Patience)"
export SETUP_NO_CALLS=true
$STD apt install -y inventree
msg_ok "Installed InvenTree"

msg_info "Configuring InvenTree"
LOCAL_IP="$(hostname -I | awk '{print $1}')"
if [[ -f /etc/inventree/config.yaml ]]; then
  sed -i "s|site_url:.*|site_url: http://${LOCAL_IP}|" /etc/inventree/config.yaml
fi
$STD inventree run invoke update
msg_ok "Configured InvenTree"

motd_ssh
customize
cleanup_lxc
