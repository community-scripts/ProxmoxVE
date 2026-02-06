#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/dani-garcia/vaultwarden

APP="Vaultwarden"
var_tags="${var_tags:-password-manager}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-20}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
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

  VAULT=$(get_latest_github_release "dani-garcia/vaultwarden")
  WVRELEASE=$(get_latest_github_release "dani-garcia/bw_web_builds")

  UPD=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUPPORT" --radiolist --cancel-button Exit-Script "Spacebar = Select" 11 58 3 \
    "1" "VaultWarden $VAULT" ON \
    "2" "Web-Vault $WVRELEASE" OFF \
    "3" "Set Admin Token" OFF \
    3>&1 1>&2 2>&3)

  if [ "$UPD" == "1" ]; then
    if check_for_gh_release "vaultwarden" "dani-garcia/vaultwarden"; then
      msg_info "Stopping Service"
      systemctl stop vaultwarden
      msg_ok "Stopped Service"

      fetch_and_deploy_gh_release "vaultwarden" "dani-garcia/vaultwarden" "tarball" "latest" "/tmp/vaultwarden-src"

      msg_info "Updating VaultWarden to $VAULT (Patience)"
      cd /tmp/vaultwarden-src
      $STD cargo build --features "sqlite,mysql,postgresql" --release
      if [[ -f /usr/bin/vaultwarden ]]; then
        cp target/release/vaultwarden /usr/bin/
      else
        cp target/release/vaultwarden /opt/vaultwarden/bin/
      fi
      cd ~ && rm -rf /tmp/vaultwarden-src
      msg_ok "Updated VaultWarden to ${VAULT}"

      msg_info "Starting Service"
      systemctl start vaultwarden
      msg_ok "Started Service"
      msg_ok "Updated successfully!"
    else
      msg_ok "VaultWarden is already up-to-date"
    fi
    exit
  fi

  if [ "$UPD" == "2" ]; then
    if check_for_gh_release "vaultwarden_webvault" "dani-garcia/bw_web_builds"; then
      msg_info "Stopping Service"
      systemctl stop vaultwarden
      msg_ok "Stopped Service"

      msg_info "Updating Web-Vault to $WVRELEASE"
      rm -rf /opt/vaultwarden/web-vault
      mkdir -p /opt/vaultwarden/web-vault

      fetch_and_deploy_gh_release "vaultwarden_webvault" "dani-garcia/bw_web_builds" "prebuild" "latest" "/opt/vaultwarden/web-vault" "bw_web_*.tar.gz"

      chown -R root:root /opt/vaultwarden/web-vault/
      msg_ok "Updated Web-Vault to ${WVRELEASE}"

      msg_info "Starting Service"
      systemctl start vaultwarden
      msg_ok "Started Service"
      msg_ok "Updated successfully!"
    else
      msg_ok "Web-Vault is already up-to-date"
    fi
    exit
  fi

  if [ "$UPD" == "3" ]; then
    if NEWTOKEN=$(whiptail --backtitle "Proxmox VE Helper Scripts" --passwordbox "Set the ADMIN_TOKEN" 10 58 3>&1 1>&2 2>&3); then
      if [[ -z "$NEWTOKEN" ]]; then exit; fi
      ensure_dependencies argon2
      TOKEN=$(echo -n "${NEWTOKEN}" | argon2 "$(openssl rand -base64 32)" -t 2 -m 16 -p 4 -l 64 -e)
      sed -i "s|ADMIN_TOKEN=.*|ADMIN_TOKEN='${TOKEN}'|" /opt/vaultwarden/.env
      if [[ -f /opt/vaultwarden/data/config.json ]]; then
        sed -i "s|\"admin_token\":.*|\"admin_token\": \"${TOKEN}\"|" /opt/vaultwarden/data/config.json
      fi
      systemctl restart vaultwarden
      msg_ok "Admin token updated"
    fi
    exit
  fi
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:8000${CL}"
