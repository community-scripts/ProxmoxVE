#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/seanmorley15/AdventureLog

APP="AdventureLog"
var_tags="${var_tags:-traveling}"
var_disk="${var_disk:-7}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
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
  if [[ ! -d /opt/adventurelog ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  ensure_dependencies memcached libmemcached-tools
  if check_for_gh_release "adventurelog" "seanmorley15/adventurelog"; then
    msg_info "Stopping Services"
    systemctl stop adventurelog-backend
    systemctl stop adventurelog-frontend
    msg_ok "Services Stopped"

    create_backup /opt/adventurelog/backend/server/.env \
      /opt/adventurelog/backend/server/media

    fetch_and_deploy_gh_release "adventurelog" "seanmorley15/adventurelog" "tarball"
    PYTHON_VERSION="3.13" setup_uv

    msg_info "Ensuring PostgreSQL Extensions"
    $STD sudo -u postgres psql -d adventurelog_db -c "CREATE EXTENSION IF NOT EXISTS postgis;"
    msg_ok "PostgreSQL Extensions Ready"

    restore_backup

    msg_info "Updating AdventureLog"
    cd /opt/adventurelog/backend/server
    if [[ ! -x .venv/bin/python ]]; then
      $STD uv venv --clear .venv
      $STD .venv/bin/python -m ensurepip --upgrade
    fi
    $STD .venv/bin/python -m pip install --upgrade pip
    $STD .venv/bin/python -m pip install -r requirements.txt
    $STD .venv/bin/python -m pip install 'djangorestframework<3.15'
    $STD .venv/bin/python -m manage collectstatic --noinput
    $STD .venv/bin/python -m manage migrate

    cd /opt/adventurelog/frontend
    grep -q "^dangerouslyAllowAllBuilds:" ./pnpm-workspace.yaml 2>/dev/null || echo "dangerouslyAllowAllBuilds: true" >>./pnpm-workspace.yaml
    $STD pnpm i
    $STD pnpm build
    msg_ok "Updated AdventureLog"

    msg_info "Starting Services"
    systemctl daemon-reexec
    systemctl start adventurelog-backend
    systemctl start adventurelog-frontend
    msg_ok "Services Started"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
