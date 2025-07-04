#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://komo.do

APP="Alpine-Komodo"
var_tags="${var_tags:-docker,alpine}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-10}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.22}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  [[ -d /opt/komodo ]] || {
    msg_error "No ${APP} Installation Found!"
    exit 1
  }

  msg_info "Updating ${APP}"
  COMPOSE_FILE=$(find /opt/komodo -maxdepth 1 -type f -name '*.compose.yaml' ! -name 'compose.env' | head -n1)
  if [[ -z "$COMPOSE_FILE" ]]; then
    msg_error "No valid compose file found in /opt/komodo!"
    exit 1
  fi
  COMPOSE_BASENAME=$(basename "$COMPOSE_FILE")

  if [[ "$COMPOSE_BASENAME" == "sqlite.compose.yaml" || "$COMPOSE_BASENAME" == "postgres.compose.yaml" ]]; then
    msg_error "❌ Detected outdated Komodo setup using SQLite or PostgreSQL (FerretDB v1)."
    echo -e "${YW}This configuration is no longer supported since Komodo v1.18.0.${CL}"
    echo -e "${YW}Please follow the migration guide:${CL}"
    echo -e "${BGN}https://github.com/community-scripts/ProxmoxVE/discussions/5689${CL}\n"
    exit 1
  fi

  BACKUP_FILE="/opt/komodo/${COMPOSE_BASENAME}.bak_$(date +%Y%m%d_%H%M%S)"
  cp "$COMPOSE_FILE" "$BACKUP_FILE" || {
    msg_error "Failed to create backup of ${COMPOSE_BASENAME}!"
    exit 1
  }
  GITHUB_URL="https://raw.githubusercontent.com/moghtech/komodo/main/compose/${COMPOSE_BASENAME}"
  if ! curl -fsSL "$GITHUB_URL" -o "$COMPOSE_FILE"; then
    msg_error "Failed to download ${COMPOSE_BASENAME} from GitHub!"
    mv "$BACKUP_FILE" "$COMPOSE_FILE"
    exit 1
  fi
  $STD docker compose -p komodo -f "$COMPOSE_FILE" --env-file /opt/komodo/compose.env up -d
  msg_ok "Updated ${APP}"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9120${CL}"
