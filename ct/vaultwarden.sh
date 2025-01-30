#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.vaultwarden.net/

# App Default Values
APP="Vaultwarden"
var_tags="password-manager"
var_cpu="4"
var_ram="6144"
var_disk="6"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/systemd/system/vaultwarden.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  VAULT=$(curl -s https://api.github.com/repos/dani-garcia/vaultwarden/releases/latest |
    grep "tag_name" |
    awk '{print substr($2, 2, length($2)-3) }')
  WVRELEASE=$(curl -s https://api.github.com/repos/dani-garcia/bw_web_builds/releases/latest |
    grep "tag_name" |
    awk '{print substr($2, 2, length($2)-3) }')

  UPD=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUPPORT" --radiolist --cancel-button Exit-Script "Spacebar = Select" 11 58 3 \
    "1" "VaultWarden $VAULT" ON \
    "2" "Web-Vault $WVRELEASE" OFF \
    "3" "Set Admin Token" OFF \
    3>&1 1>&2 2>&3)

  if [ "$UPD" == "1" ]; then
    msg_info "Stopping Vaultwarden"
    systemctl stop vaultwarden.service
    msg_ok "Stopped Vaultwarden"

    msg_info "Updating VaultWarden to $VAULT (Patience)"
    cd ~ && rm -rf vaultwarden
    git clone https://github.com/dani-garcia/vaultwarden &>/dev/null
    cd vaultwarden
    cargo build --features "sqlite,mysql,postgresql" --release &>/dev/null
    DIR=/usr/bin/vaultwarden
    if [ -d "$DIR" ]; then
      cp target/release/vaultwarden /usr/bin/
    else
      cp target/release/vaultwarden /opt/vaultwarden/bin/
    fi
    msg_ok "Updated VaultWarden"

    msg_info "Cleaning up"
    cd ~ && rm -rf vaultwarden
    msg_ok "Cleaned"

    msg_info "Starting Vaultwarden"
    systemctl start vaultwarden.service
    msg_ok "Started Vaultwarden"

    msg_ok "$VAULT Update Successful"
    exit
  fi
  if [ "$UPD" == "2" ]; then
    msg_info "Stopping Vaultwarden"
    systemctl stop vaultwarden.service
    msg_ok "Stopped Vaultwarden"

    msg_info "Updating Web-Vault to $WVRELEASE"
    curl -fsSLO https://github.com/dani-garcia/bw_web_builds/releases/download/$WVRELEASE/bw_web_$WVRELEASE.tar.gz &>/dev/null
    tar -zxf bw_web_$WVRELEASE.tar.gz -C /opt/vaultwarden/ &>/dev/null
    msg_ok "Updated Web-Vault"

    msg_info "Cleaning up"
    rm bw_web_$WVRELEASE.tar.gz
    msg_ok "Cleaned"

    msg_info "Starting Vaultwarden"
    systemctl start vaultwarden.service
    msg_ok "Started Vaultwarden"
    msg_ok "$WVRELEASE Update Successful"
    exit
  fi
  if [ "$UPD" == "3" ]; then
    if NEWTOKEN=$(whiptail --backtitle "Proxmox VE Helper Scripts" --passwordbox "Set the ADMIN_TOKEN" 10 58 3>&1 1>&2 2>&3); then
      if [[ -z "$NEWTOKEN" ]]; then exit; fi
      if ! command -v argon2 >/dev/null 2>&1; then apt-get install -y argon2 &>/dev/null; fi
      TOKEN=$(echo -n ${NEWTOKEN} | argon2 "$(openssl rand -base64 32)" -t 2 -m 16 -p 4 -l 64 -e)
      sed -i "s|ADMIN_TOKEN=.*|ADMIN_TOKEN='${TOKEN}'|" /opt/vaultwarden/.env
      if [[ -f /opt/vaultwarden/data/config.json ]]; then
        sed -i "s|\"admin_token\":.*|\"admin_token\": \"${TOKEN}\"|" /opt/vaultwarden/data/config.json
      fi
      systemctl restart vaultwarden
    fi
    exit
  fi
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
