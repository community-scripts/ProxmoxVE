#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Fabian Pulch (fpulch)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/paperclipai/paperclip

APP="Paperclip"
var_tags="${var_tags:-ai;automation;dev-tools}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-20}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"
export var_paperclip_user="${var_paperclip_user:-}"
export var_paperclip_pass="${var_paperclip_pass:-}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/paperclip-ai ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "paperclip-ai" "paperclipai/paperclip"; then
    msg_info "Stopping Service"
    systemctl stop paperclip
    msg_ok "Stopped Service"

    create_backup /opt/paperclip-ai/.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "paperclip-ai" "paperclipai/paperclip" "tarball"

    restore_backup

    setup_rust

    msg_info "Rebuilding Paperclip"
    cd /opt/paperclip-ai
    export HUSKY=0
    export NODE_OPTIONS="--max-old-space-size=8192"
    $STD pnpm install --frozen-lockfile
    $STD pnpm build
    unset NODE_OPTIONS
    msg_ok "Rebuilt Paperclip"

    msg_info "Updating Agent CLIs"
    $STD npm install -g \
      @anthropic-ai/claude-code@latest \
      @openai/codex@latest
    msg_ok "Updated Agent CLIs"

    # Claude Code refuses --dangerously-skip-permissions as root; migrate existing installs to a dedicated user
    PAPERCLIP_USER=$(sed -n 's/^User=//p' /etc/systemd/system/paperclip.service)
    if [[ -z "$PAPERCLIP_USER" || "$PAPERCLIP_USER" == "root" ]]; then
      PAPERCLIP_USER="${var_paperclip_user:-paperclip}"
      if [[ "$PAPERCLIP_USER" == "root" || ! "$PAPERCLIP_USER" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
        msg_error "Invalid var_paperclip_user '${PAPERCLIP_USER}' (must be a non-root lowercase Linux username)"
        exit 1
      fi
      PAPERCLIP_USER_HOME="/home/${PAPERCLIP_USER}"
      id -u "$PAPERCLIP_USER" &>/dev/null || useradd -m -d "$PAPERCLIP_USER_HOME" -s /bin/bash "$PAPERCLIP_USER"
      passwd -S "$PAPERCLIP_USER" 2>/dev/null | grep -q " P " || passwd -l "$PAPERCLIP_USER" &>/dev/null
      mkdir -p "${PAPERCLIP_USER_HOME}/.claude" "${PAPERCLIP_USER_HOME}/.codex"
      [[ -d /root/.claude ]] && cp -a /root/.claude/. "${PAPERCLIP_USER_HOME}/.claude/"
      [[ -d /root/.codex ]] && cp -a /root/.codex/. "${PAPERCLIP_USER_HOME}/.codex/"
      sed -i \
        -e "s|^User=.*|User=${PAPERCLIP_USER}\nGroup=${PAPERCLIP_USER}|" \
        -e "s|^Environment=HOME=.*|Environment=HOME=${PAPERCLIP_USER_HOME}|" \
        -e "s|^Environment=CODEX_HOME=.*|Environment=CODEX_HOME=${PAPERCLIP_USER_HOME}/.codex|" \
        -e "s|/root/.local/bin|${PAPERCLIP_USER_HOME}/.local/bin|" \
        /etc/systemd/system/paperclip.service
      systemctl daemon-reload
    fi
    PAPERCLIP_USER_HOME=$(getent passwd "$PAPERCLIP_USER" | cut -d: -f6)
    chmod 600 /opt/paperclip-ai/.env
    chown -R "${PAPERCLIP_USER}:${PAPERCLIP_USER}" /opt/paperclip-ai /opt/paperclip-data "$PAPERCLIP_USER_HOME"

    msg_info "Running Database Migrations"
    set -a && source /opt/paperclip-ai/.env && set +a
    $STD runuser -u "$PAPERCLIP_USER" -- env HOME="$PAPERCLIP_USER_HOME" bash -c 'cd /opt/paperclip-ai && pnpm db:migrate'
    msg_ok "Ran Database Migrations"

    msg_info "Starting Service"
    systemctl start paperclip
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3100${CL}"
