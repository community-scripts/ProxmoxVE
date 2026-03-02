#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://komo.do/

APP="Alpine-Komodo"
var_tags="${var_tags:-docker;alpine}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-10}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.23}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

ADDON_SCRIPT="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/komodo.sh"

function update_script() {
  if [[ ! -d /opt/komodo ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_warn "⚠️  ${APP} has been migrated to an addon script."
  echo ""
  msg_info "This is a one-time migration. After this, you can update ${APP} anytime with:"
  echo -e "${TAB}${TAB}${GN}update_komodo${CL}  or  ${GN}bash <(curl -fsSL ${ADDON_SCRIPT})${CL}"
  echo ""
  read -r -p "${TAB}Migrate update function now? [y/N]: " CONFIRM
  if [[ ! "${CONFIRM,,}" =~ ^(y|yes)$ ]]; then
    msg_warn "Migration skipped. The old update will continue to work for now."
    msg_info "Updating ${APP} (legacy)"
    COMPOSE_FILE=$(find /opt/komodo -maxdepth 1 -type f -name '*.compose.yaml' ! -name 'compose.env' | head -n1)
    if [[ -z "$COMPOSE_FILE" ]]; then
      msg_error "No valid compose file found in /opt/komodo!"
      exit 252
    fi
    $STD docker compose -p komodo -f "$COMPOSE_FILE" --env-file /opt/komodo/compose.env pull
    $STD docker compose -p komodo -f "$COMPOSE_FILE" --env-file /opt/komodo/compose.env up -d
    msg_ok "Updated ${APP}"
    exit
  fi

  msg_info "Migrating update function"
  cat <<'MIGRATION_EOF' >/usr/bin/update
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/komodo.sh)"
MIGRATION_EOF
  chmod +x /usr/bin/update

  ln -sf /usr/bin/update /usr/bin/update_komodo 2>/dev/null || true
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9120${CL}"
