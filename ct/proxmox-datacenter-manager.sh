#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: Proxmox Server Solution GmbH

APP="Proxmox-Datacenter-Manager"
var_tags="${var_tags:-datacenter}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

WEB_UI_PORT=8443
WEB_UI_PROTOCOL="https"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -e /usr/sbin/proxmox-datacenter-manager-admin ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if grep -q 'Debian GNU/Linux 12' /etc/os-release && [ -f /etc/apt/sources.list.d/proxmox-release-bookworm.list ] && [ -f /etc/apt/sources.list.d/pdm-test.list ]; then
    msg_info "Updating outdated outdated source formats"
    echo "deb [signed-by=/usr/share/keyrings/proxmox-archive-keyring.gpg] http://download.proxmox.com/debian/pdm bookworm pdm-test" >/etc/apt/sources.list.d/pdm-test.list
    curl -fsSL https://enterprise.proxmox.com/debian/proxmox-archive-keyring-trixie.gpg -o /usr/share/keyrings/proxmox-archive-keyring.gpg
    rm -f /etc/apt/keyrings/proxmox-release-bookworm.gpg /etc/apt/sources.list.d/proxmox-release-bookworm.list
    $STD apt update
    msg_ok "Updated old sources"
  fi

  if grep -q 'Debian GNU/Linux 13' /etc/os-release; then
    if [ -f "/etc/apt/sources.list.d/pdm-test.sources" ]; then
      if ! grep -qx "Enabled: false" "/etc/apt/sources.list.d/pdm-test.sources"; then
          echo "Enabled: false" >> "/etc/apt/sources.list.d/pdm-test.sources"
          setup_deb822_repo \
            "pdm" \
            "https://enterprise.proxmox.com/debian/proxmox-archive-keyring-trixie.gpg" \
            "http://download.proxmox.com/debian/pdm" \
            "trixie" \
            "pdm-no-subscription"
      fi
    fi
  fi

  msg_info "Updating $APP LXC"
  $STD apt update
  $STD apt -y upgrade
  msg_ok "Updated $APP LXC"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:8443${CL}"
