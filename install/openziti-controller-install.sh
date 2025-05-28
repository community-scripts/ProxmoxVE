#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: emoscardini
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/openziti/ziti

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing openziti"
mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://get.openziti.io/tun/package-repos.gpg | gpg --dearmor -o /usr/share/keyrings/openziti.gpg
echo "deb [signed-by=/usr/share/keyrings/openziti.gpg] https://packages.openziti.org/zitipax-openziti-deb-stable debian main" >/etc/apt/sources.list.d/openziti.list
$STD apt-get update
$STD apt-get install -y openziti-controller openziti-console
msg_ok "Installed openziti"

read -r -p "${TAB3}Would you like to go through the auto configuration now? <y/N>" prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  IPADDRESS=$(hostname -I | awk '{print $1}')
  GEN_FQDN="controller.${IPADDRESS}.sslip.io"
  read -r -p "${TAB3}Please enter the controller FQDN [${GEN_FQDN}]: " ZITI_CTRL_ADVERTISED_ADDRESS
  ZITI_CTRL_ADVERTISED_ADDRESS=${ZITI_CTRL_ADVERTISED_ADDRESS:-$GEN_FQDN}
  read -r -p "${TAB3}Please enter the controller port [1280]: " ZITI_CTRL_ADVERTISED_PORT
  ZITI_CTRL_ADVERTISED_PORT=${ZITI_CTRL_ADVERTISED_PORT:-1280}
  read -r -p "${TAB3}Please enter the controller admin user [admin]: " ZITI_USER
  ZITI_USER=${ZITI_USER:-admin}
  GEN_PWD=$(head -c128 /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^*_+~' | cut -c 1-12)
  read -r -p "${TAB3}Please enter the controller admin password [${GEN_PWD}]:" ZITI_PWD
  ZITI_PWD=${ZITI_PWD:-$GEN_PWD}
  CONFIG_FILE="/opt/openziti/etc/controller/bootstrap.env"
  sed -i "s|^ZITI_CTRL_ADVERTISED_ADDRESS=.*|ZITI_CTRL_ADVERTISED_ADDRESS='${ZITI_CTRL_ADVERTISED_ADDRESS}'|" "$CONFIG_FILE"
  sed -i "s|^ZITI_CTRL_ADVERTISED_PORT=.*|ZITI_CTRL_ADVERTISED_PORT='${ZITI_CTRL_ADVERTISED_PORT}'|" "$CONFIG_FILE"
  sed -i "s|^ZITI_USER=.*|ZITI_USER='${ZITI_USER}'|" "$CONFIG_FILE"
  sed -i "s|^ZITI_PWD=.*|ZITI_PWD='${ZITI_PWD}'|" "$CONFIG_FILE"
  env VERBOSE=0 bash /opt/openziti/etc/controller/bootstrap.bash
  msg_ok "Configuration Completed"
  systemctl enable -q --now ziti-controller
else
  systemctl enable -q ziti-controller
  msg_error "Configration not provided; Please run /opt/openziti/etc/controller/bootstrap.bash to configure the controller and restart the container"
fi

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
