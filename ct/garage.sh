#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://garagehq.deuxfleurs.fr/

APP="Garage"
var_tags="${var_tags:-object-storage}"
var_cpu="${var_cpu:-1}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"
if [[ -z "${var_os:-}" ]] && command -v pveversion >/dev/null 2>&1; then
  var_os=$(msg_menu "Choose the container OS" \
    "debian" "Debian 13" \
    "alpine" "Alpine (smaller footprint)")
fi

if [[ "${var_os:-}" == "alpine" ]]; then
  var_ram="${var_ram:-512}"
  var_disk="${var_disk:-5}"
  var_version="${var_version:-3.24}"
else
  var_ram="${var_ram:-1024}"
  var_disk="${var_disk:-5}"
  var_version="${var_version:-13}"
fi

header_info "$APP"
variables
color
catch_errors

update_deb_based() {
  if [[ ! -f /usr/local/bin/garage ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  GITEA_RELEASE=$(curl -fsSL https://api.github.com/repos/deuxfleurs-org/garage/tags | jq -r '.[0].name')
  if [[ "${GITEA_RELEASE}" != "$(cat ~/.garage 2>/dev/null)" ]] || [[ ! -f ~/.garage ]]; then
    msg_info "Stopping Service"
    systemctl stop garage
    msg_ok "Stopped Service"

    msg_info "Backing Up Data"
    cp /usr/local/bin/garage /usr/local/bin/garage.old 2>/dev/null || true
    cp /etc/garage.toml /etc/garage.toml.bak 2>/dev/null || true
    msg_ok "Backed Up Data"

    msg_info "Updating Garage"
    curl -fsSL "https://garagehq.deuxfleurs.fr/_releases/${GITEA_RELEASE}/$(arch_resolve "x86_64" "aarch64")-unknown-linux-musl/garage" -o /usr/local/bin/garage
    chmod +x /usr/local/bin/garage
    echo "${GITEA_RELEASE}" >~/.garage
    msg_ok "Updated Garage"

    msg_info "Starting Service"
    systemctl start garage
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. Garage is already at ${GITEA_RELEASE}"
  fi
}

update_alpine() {
  if [[ ! -f /usr/local/bin/garage ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  GITEA_RELEASE=$(curl -fsSL https://api.github.com/repos/deuxfleurs-org/garage/tags | jq -r '.[0].name')
  if [[ "${GITEA_RELEASE}" != "$(cat ~/.garage 2>/dev/null)" ]] || [[ ! -f ~/.garage ]]; then
    msg_info "Stopping Service"
    rc-service garage stop || true
    msg_ok "Stopped Service"

    msg_info "Backing Up Data"
    cp /usr/local/bin/garage /usr/local/bin/garage.old 2>/dev/null || true
    cp /etc/garage.toml /etc/garage.toml.bak 2>/dev/null || true
    msg_ok "Backed Up Data"

    msg_info "Updating Garage"
    curl -fsSL "https://garagehq.deuxfleurs.fr/_releases/${GITEA_RELEASE}/$(arch_resolve "x86_64" "aarch64")-unknown-linux-musl/garage" -o /usr/local/bin/garage
    chmod +x /usr/local/bin/garage
    echo "${GITEA_RELEASE}" >~/.garage
    msg_ok "Updated Garage"

    msg_info "Starting Service"
    rc-service garage start || rc-service garage restart
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. Garage is already at ${GITEA_RELEASE}"
  fi
}

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  run_os_update
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
