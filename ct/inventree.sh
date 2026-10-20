#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/inventree/InvenTree

APP="InvenTree"
var_tags="${var_tags:-inventory}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d "/opt/inventree" ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if ! grep -qE "^ID=(ubuntu|debian)$" /etc/os-release; then
    msg_error "Unsupported OS. InvenTree requires Ubuntu or Debian."
    exit
  fi

  # dl.packager.io is frozen at 1.5.1 and its SHA1-bound key fails on Debian 13;
  # go.packager.io only carries current builds for these releases
  if grep -qs "dl.packager.io" /etc/apt/sources.list.d/inventree*; then
    case "$(get_os_info id)/$(get_os_info version)" in
    ubuntu/24.04 | ubuntu/26.04 | debian/13)
      msg_info "Migrating InvenTree Repository"
      setup_deb822_repo \
        "inventree" \
        "https://go.packager.io/srv/deb/inventree/InvenTree/gpg-key.asc" \
        "https://go.packager.io/srv/deb/inventree/InvenTree/stable/$(get_os_info id)" \
        "$(get_os_info version)" \
        "main"
      msg_ok "Migrated InvenTree Repository"
      ;;
    *)
      msg_warn "InvenTree only publishes updates for Ubuntu 24.04/26.04 and Debian 13; staying on the frozen repository"
      ;;
    esac
  fi

  msg_info "Updating InvenTree"
  apt_update_safe
  # postinst loops forever unless its parent chain reaches PID 1 (not the case under pct exec)
  $STD systemd-run --wait --pipe --quiet --collect --setenv=DEBIAN_FRONTEND=noninteractive \
    apt-get install --only-upgrade -y inventree
  msg_ok "Updated InvenTree"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
