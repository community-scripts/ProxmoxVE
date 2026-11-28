#!/usr/bin/env bash
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
  systemctl restart garage
}

update_alpine() {
  rc-service garage restart || rc-service garage start
}

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /usr/local/bin/garage ]]; then
    msg_error "No Garage installation found"
    exit 1
  fi

  local garage_release garage_binary
  garage_release=$(curl -fsSL https://git.deuxfleurs.fr/api/v1/repos/Deuxfleurs/garage/releases/latest |
    jq -er 'select(.draft == false and .prerelease == false) | .tag_name | strings | select(length > 0)') || {
    msg_error "Could not determine the latest stable Garage release"
    exit 1
  }
  if [[ -f ~/.garage && "$garage_release" == "$(<~/.garage)" ]]; then
    msg_ok "No update required. Garage is already at ${garage_release}"
    exit 0
  fi

  msg_info "Downloading Garage ${garage_release}"
  garage_binary=$(mktemp /usr/local/bin/garage.XXXXXX)
  if ! download_file "https://garagehq.deuxfleurs.fr/_releases/${garage_release}/$(arch_resolve "x86_64" "aarch64")-unknown-linux-musl/garage" "$garage_binary"; then
    rm -f "$garage_binary"
    exit 1
  fi
  msg_ok "Downloaded Garage ${garage_release}"

  msg_info "Backing up Garage"
  cp /usr/local/bin/garage /usr/local/bin/garage.old 2>/dev/null || true
  cp /etc/garage.toml /etc/garage.toml.bak 2>/dev/null || true
  msg_ok "Backed up Garage"

  msg_info "Updating Garage"
  chmod 755 "$garage_binary"
  mv -f "$garage_binary" /usr/local/bin/garage
  msg_ok "Updated Garage"

  msg_info "Restarting Garage"
  run_os_update
  msg_ok "Restarted Garage"
  printf '%s\n' "$garage_release" >~/.garage
  msg_ok "Updated Garage successfully"
  exit 0
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Use this Garage S3 API endpoint${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3900${CL}"
