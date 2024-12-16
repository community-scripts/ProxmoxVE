#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
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
$STD apk add newt
$STD apk add curl
$STD apk add openssl
$STD apk add openssh
$STD apk add nano
$STD apk add mc
$STD apk add argon2
msg_ok "Installed Dependencies"

msg_info "Installing Alpine-Vaultwarden"
$STD apk add vaultwarden
sed -i -e 's|export WEB_VAULT_ENABLED=.*|export WEB_VAULT_ENABLED=true|' /etc/conf.d/vaultwarden
echo -e "export ADMIN_TOKEN=''" >>/etc/conf.d/vaultwarden
echo -e "export ROCKET_ADDRESS=0.0.0.0" >>/etc/conf.d/vaultwarden
msg_ok "Installed Alpine-Vaultwarden"

msg_info "Installing Web-Vault"
$STD apk add vaultwarden-web-vault
msg_ok "Installed Web-Vault" 

msg_info "Starting Alpine-Vaultwarden"
$STD rc-service vaultwarden start
$STD rc-update add vaultwarden default
msg_ok "Started Alpine-Vaultwarden"

motd_ssh
customize
