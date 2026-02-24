#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://coolify.io/

APP="Coolify"
var_tags="${var_tags:-docker;paas}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-30}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

ADDON_SCRIPT="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/coolify.sh"

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /data/coolify ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_warn "⚠️  ${APP} has been migrated to an addon script."
  echo ""
  msg_info "This is a one-time migration. After this, you can update ${APP} anytime with:"
  echo -e "${TAB}${TAB}${GN}update_coolify${CL}  or  ${GN}bash <(curl -fsSL ${ADDON_SCRIPT})${CL}"
  echo ""
  read -r -p "${TAB}Migrate update function now? [y/N]: " CONFIRM
  if [[ ! "${CONFIRM,,}" =~ ^(y|yes)$ ]]; then
    msg_warn "Migration skipped. The old update will continue to work for now."
    msg_info "Updating ${APP} (legacy)"
    $STD bash <(curl -fsSL https://cdn.coollabs.io/coolify/install.sh)
    msg_ok "Updated ${APP}"
    exit
  fi

  msg_info "Migrating update function"
  cat <<'MIGRATION_EOF' >/usr/bin/update
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/coolify.sh)"
MIGRATION_EOF
  chmod +x /usr/bin/update

  ln -sf /usr/bin/update /usr/bin/update_coolify 2>/dev/null || true
  msg_ok "Migration complete"

  msg_info "Running addon update"
  type=update bash <(curl -fsSL "${ADDON_SCRIPT}")
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
