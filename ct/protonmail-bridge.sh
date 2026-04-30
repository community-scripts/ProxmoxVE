#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Stephen Chin (steveonjava)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ProtonMail/proton-bridge

APP="ProtonMail-Bridge"
var_tags="${var_tags:-mail;proton}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
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

  if [[ ! -x /usr/bin/protonmail-bridge ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  if check_for_gh_release "protonmail-bridge" "ProtonMail/proton-bridge"; then
    local -a bridge_units=(
      protonmail-bridge
      protonmail-bridge-imap.socket
      protonmail-bridge-smtp.socket
      protonmail-bridge-imap-proxy
      protonmail-bridge-smtp-proxy
    )
    local unit
    declare -A was_active
    for unit in "${bridge_units[@]}"; do
      if systemctl is-active --quiet "$unit" 2>/dev/null; then
        was_active["$unit"]=1
      else
        was_active["$unit"]=0
      fi
    done

    msg_info "Stopping Services"
    systemctl stop protonmail-bridge-imap.socket protonmail-bridge-smtp.socket protonmail-bridge-imap-proxy protonmail-bridge-smtp-proxy protonmail-bridge
    msg_ok "Stopped Services"

    fetch_and_deploy_gh_release "protonmail-bridge" "ProtonMail/proton-bridge" "binary"

    if [[ -f /home/protonbridge/.protonmailbridge-initialized ]]; then
      msg_info "Starting Services"
      for unit in "${bridge_units[@]}"; do
        if [[ "${was_active[$unit]:-0}" == "1" ]]; then
          systemctl start "$unit"
        fi
      done
      msg_ok "Started Services"
    else
      msg_ok "Initialization not completed. Services remain disabled."
    fi
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}One-time configuration is required before Bridge services are enabled.${CL}"
echo -e "${INFO}${YW}Run this command in the container: protonmailbridge-configure${CL}"
