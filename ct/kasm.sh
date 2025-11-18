#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Omar Minaya
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.kasmweb.com/docs/latest/index.html

APP="Kasm"
var_tags="${var_tags:-os}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-30}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-0}"
var_fuse="${var_fuse:-yes}"
var_tun="${var_tun:-yes}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/kasm/current ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Checking for new version"
  CURRENT_VERSION=$(readlink -f /opt/kasm/current | awk -F'/' '{print $4}')
  KASM_URL=$(curl -fsSL "https://www.kasm.com/downloads" | tr '\n' ' ' | grep -oE 'https://kasm-static-content[^"]*kasm_release_[0-9]+\.[0-9]+\.[0-9]+\.[a-z0-9]+\.tar\.gz' | head -n 1)
  if [[ -z "$KASM_URL" ]]; then
    msg_error "Unable to detect latest Kasm release URL."
    exit 1
  fi
  KASM_VERSION=$(echo "$KASM_URL" | sed -E 's/.*kasm_release_([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
  msg_info "Checked for new version"

  msg_info "Removing outdated docker-compose plugin"
  [ -f ~/.docker/cli-plugins/docker-compose ] && rm -rf ~/.docker/cli-plugins/docker-compose
  msg_ok "Removed outdated docker-compose plugin"
  
  if [[ -z "$CURRENT_VERSION" ]] || [[ "$KASM_VERSION" != "$CURRENT_VERSION" ]]; then
    msg_info "Updating Kasm"
    cd /tmp

    msg_warn "WARNING: This script will run an external installer from a third-party source (https://www.kasmweb.com/)."
    msg_warn "The following code is NOT maintained or audited by our repository."
    msg_warn "If you have any doubts or concerns, please review the installer code before proceeding:"
    msg_custom "${TAB3}${GATEWAY}${BGN}${CL}" "\e[1;34m" "→  upgrade.sh inside tar.gz $KASM_URL"
    echo
    read -r -p "${TAB3}Do you want to continue? [y/N]: " CONFIRM
    if [[ ! "$CONFIRM" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      msg_error "Aborted by user. No changes have been made."
      exit 10
    fi
    curl -fsSL -o "/tmp/kasm_release_${KASM_VERSION}.tar.gz" "$KASM_URL"
    tar -xf "kasm_release_${KASM_VERSION}.tar.gz"
    chmod +x /tmp/kasm_release/install.sh
    rm -f /tmp/kasm_release_${KASM_VERSION}.tar.gz
  
    bash /tmp/kasm_release/upgrade.sh --proxy-port 443
    rm -rf /tmp/kasm_release
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. Kasm is already at v${KASM_VERSION}"
  
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}${CL}"
