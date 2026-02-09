#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/dani-garcia/vaultwarden

APP="Alpine-Vaultwarden"
var_tags="${var_tags:-alpine;vault}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
var_disk="${var_disk:-1}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.23}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  CHOICE=$(msg_menu "Vaultwarden Update Options" \
    "1" "Update Vaultwarden" \
    "2" "Reset ADMIN_TOKEN")

  case $CHOICE in
  1)
    $STD apk -U upgrade
    rc-service vaultwarden restart -q
    msg_ok "Updated successfully!"
    exit
    ;;
  2)
    if [[ "${PHS_SILENT:-0}" == "1" ]]; then
      msg_warn "Reset ADMIN_TOKEN requires interactive mode, skipping."
      exit
    fi
    read -r -s -p "Setup your ADMIN_TOKEN (make it strong): " NEWTOKEN
    echo ""
    if [[ -n "$NEWTOKEN" ]]; then
      if ! command -v argon2 >/dev/null 2>&1; then apk add argon2 &>/dev/null; fi
      TOKEN=$(echo -n "${NEWTOKEN}" | argon2 "$(openssl rand -base64 32)" -e -id -k 19456 -t 2 -p 1)
      if [[ ! -f /var/lib/vaultwarden/config.json ]]; then
        sed -i "s|export ADMIN_TOKEN=.*|export ADMIN_TOKEN='${TOKEN}'|" /etc/conf.d/vaultwarden
      else
        sed -i "s|\"admin_token\": .*|\"admin_token\": \"${TOKEN}\",|" /var/lib/vaultwarden/config.json
      fi
      rc-service vaultwarden restart -q
      msg_ok "Admin token updated"
    fi
    exit
    ;;
  esac
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}https://${IP}:8000${CL} \n"
