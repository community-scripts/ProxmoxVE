#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/frappe/erpnext

APP="ERPNext"
var_tags="${var_tags:-erp;business;accounting}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/frappe-bench ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  FRAPPE_MAJOR="$(grep -oP '__version__\s*=\s*[\x27"]\K[0-9]+' /opt/frappe-bench/apps/frappe/frappe/__init__.py 2>/dev/null || echo 0)"
  SITE="$(ls /opt/frappe-bench/sites/*/site_config.json 2>/dev/null | head -1 | cut -d/ -f5)"
  [[ -z "$SITE" ]] && SITE="site1.local"

  if [[ "${FRAPPE_MAJOR:-0}" -lt 16 ]] && { [[ "${PHS_SILENT:-0}" == "1" ]] || whiptail --backtitle "Proxmox VE Helper Scripts" --title "ERPNext v16 Major Upgrade" \
    --yesno "A major upgrade from Frappe/ERPNext v15 to v16 is available.\n\nUpgrade to v16 now?" 16 78; }; then

    msg_info "Backing up site ${SITE}"
    $STD sudo -u frappe bash -c "export PATH=\"\$HOME/.local/bin:/usr/local/bin:\$PATH\"; cd /opt/frappe-bench && bench --site ${SITE} backup"
    msg_ok "Backup created"

    msg_info "Installing Dependencies"
    $STD apt-get install -y pkg-config
    $STD sudo -u frappe bash -c 'export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"; uv python install 3.14'
    msg_ok "Installed Dependencies"

    msg_info "Migrating bench environment"
    $STD sudo -u frappe bash -c 'export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"; cd /opt/frappe-bench && bench migrate-env "$(uv python find 3.14)"'
    msg_ok "Migrated environment"

    msg_info "Switching Frappe and ERPNext to v16 (Patience)"
    $STD sudo -u frappe bash -c 'export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"; cd /opt/frappe-bench && bench switch-to-branch version-16 frappe erpnext --upgrade' || true
    NEW_MAJOR="$(grep -oP '__version__\s*=\s*[\x27"]\K[0-9]+' /opt/frappe-bench/apps/frappe/frappe/__init__.py 2>/dev/null || echo 0)"
    if [[ "${NEW_MAJOR:-0}" -lt 16 ]]; then
      msg_error "Failed to switch Frappe/ERPNext to v16"
      exit 250
    fi
    msg_ok "Switched to v16"

    msg_info "Running database migration (Patience)"
    for i in 1 2 3; do
      $STD sudo -u frappe bash -c "export PATH=\"\$HOME/.local/bin:/usr/local/bin:\$PATH\"; cd /opt/frappe-bench && bench --site ${SITE} migrate" && break
      [[ "$i" -eq 3 ]] && {
        msg_error "Database migration failed after 3 attempts"
        exit 253
      }
    done
    msg_ok "Database migrated"

    msg_info "Building assets"
    $STD sudo -u frappe bash -c 'export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"; cd /opt/frappe-bench && bench build --production'
    msg_ok "Assets built"

    msg_info "Restarting ERPNext"
    $STD sudo -u frappe bash -c 'export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"; cd /opt/frappe-bench && bench restart'
    msg_ok "Upgraded ERPNext to v16"
  else
    msg_info "Updating ERPNext"
    $STD sudo -u frappe bash -c 'export PATH="$HOME/.local/bin:$PATH"; cd /opt/frappe-bench && bench update --reset'
    msg_ok "Updated ERPNext"
  fi
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}${CL}"
echo -e "${INFO}${YW} Credentials:${CL}"
echo -e "${TAB}${BGN}Username: Administrator${CL}"
echo -e "${TAB}${BGN}Password: see ~/erpnext.creds${CL}"
