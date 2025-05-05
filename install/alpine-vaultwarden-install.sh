#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster) | Co-Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/dani-garcia/vaultwarden

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apk add --no-cache \
  openssl \
  argon2
msg_ok "Installed Dependencies"

msg_info "Installing Alpine-Vaultwarden"
$STD apk add --no-cache vaultwarden
sed -i 's|export WEB_VAULT_ENABLED=.*|export WEB_VAULT_ENABLED=true|' /etc/conf.d/vaultwarden
echo -e "export ADMIN_TOKEN=''" >>/etc/conf.d/vaultwarden
echo -e "export ROCKET_ADDRESS=0.0.0.0" >>/etc/conf.d/vaultwarden
echo -e "export ROCKET_TLS='{certs=\"/etc/ssl/certs/vaultwarden-selfsigned.crt\",key=\"/etc/ssl/private/vaultwarden-selfsigned.key\"}'" >>/etc/conf.d/vaultwarden
$STD openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout /etc/ssl/private/vaultwarden-selfsigned.key -out /etc/ssl/certs/vaultwarden-selfsigned.crt -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost"
chown vaultwarden:vaultwarden /etc/ssl/certs/vaultwarden-selfsigned.crt
chown vaultwarden:vaultwarden /etc/ssl/private/vaultwarden-selfsigned.key
msg_ok "Installed Alpine-Vaultwarden"

msg_info "Installing Web-Vault"
$STD apk add --no-cache vaultwarden-web-vault
msg_ok "Installed Web-Vault"

msg_info "Starting Alpine-Vaultwarden"
$STD rc-service vaultwarden start
$STD rc-update add vaultwarden default
msg_ok "Started Alpine-Vaultwarden"

motd_ssh
customize
