#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/dannyvfilms/Floppy

APP="Floppy"
var_tags="${var_tags:-media;tracker;movies;anime}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-no}" # unset = ask the user; set yes/no only when verified
var_unprivileged="${var_unprivileged:-1}"

export var_admin_user="${var_admin_user:-}"
export var_admin_pass="${var_admin_pass:-}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/floppy ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "floppy" "dannyvfilms/Floppy"; then
    msg_info "Stopping Floppy"
    systemctl stop floppy-celery floppy
    msg_ok "Stopped Floppy"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "floppy" "dannyvfilms/Floppy" "tarball"
    PYTHON_VERSION="3.12" UV_PROJECT_DIR="/opt/floppy" setup_uv

    msg_info "Updating Floppy"
    cd /opt/floppy
    $STD uv sync --locked --no-default-groups
    sed -i "s/^VERSION=.*/VERSION=v$(cat ~/.floppy)/" /opt/floppy_data/.env
    set -a
    source /opt/floppy_data/.env
    set +a
    cd /opt/floppy/src
    $STD /opt/floppy/.venv/bin/python manage.py migrate --noinput
    $STD /opt/floppy/.venv/bin/python manage.py collectstatic --noinput
    msg_ok "Updated Floppy"

    msg_info "Starting Floppy"
    systemctl start floppy floppy-celery
    msg_ok "Started Floppy"
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
echo -e "${GATEWAY}${BGN}http://${IP}:8000${CL}"
echo -e "${INFO}${YW}Admin credentials: /opt/floppy_data/.env${CL}"
